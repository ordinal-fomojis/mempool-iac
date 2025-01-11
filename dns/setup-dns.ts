import { Vercel } from '@vercel/sdk'
import { z } from 'zod'
import child_process from 'child_process'
import { promisify } from 'util'
const exec = promisify(child_process.exec)

const TOKEN = process.env.VERCEL_TOKEN!
const DOMAIN = process.env.DOMAIN!
const SUB_DOMAIN = process.env.SUB_DOMAIN!
const TEAM_SLUG = process.env.TEAM_SLUG!

const K8S_SERVICE_SCHEMA = z.object({
  items: z.array(z.object({
    status: z.object({
      loadBalancer: z.object({
        ingress: z.array(z.object({
          ip: z.string()
        })).optional()
      })
    })
  }))
})

const vercel = new Vercel({ bearerToken: TOKEN })

const ip = await getIpAddress()
const teamId = await getTeamId()
const record = await getDnsRecord(teamId)
await updateDnsRecord(teamId, record, ip)

async function updateDnsRecord(teamId: string, record: Awaited<ReturnType<typeof getDnsRecord>>, ip: string) {
  if (record != null && record.value === ip) {
    console.log(`DNS record already set to ${ip}. No changes required.`)
    return
  }

  if (record == null) {
    await createDnsRecord(teamId, ip)
    return
  }

  console.log(`DNS record exists but is out of date. Updating record to ${ip}.`)
  await vercel.dns.updateRecord({
    recordId: record.id,
    teamId,
    requestBody: {
      value: ip
    }
  })
  console.log(`DNS record updated to ${ip}.`)
}

async function createDnsRecord(teamId: string, ip: string) {
  // WORKAROUND: The Vercel SDK is broken due to a misconfigured zod schema, so must use the rest API directly.
  console.log(`DNS record does not exist. Creating record for ${ip}.`)
  const encodedDomain = encodeURIComponent(DOMAIN)
  const encodedTeamId = encodeURIComponent(teamId)
  const url = `https://api.vercel.com/v2/domains/${encodedDomain}/records?teamId=${encodedTeamId}`
  const response = await fetch(url, {
    body: JSON.stringify({
      name: SUB_DOMAIN,
      type: "A",
      value: ip
    }),
    headers: { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json" },
    method: "post"
  })
  if (response.ok) {
    console.log(`DNS record created for ${ip}.`)
  } else {
    throw new Error(`Failed to create DNS record: ${response.status} ${response.statusText}`)
  }
}

async function getTeamId() {
  const teams = await vercel.teams.getTeams({})
  const team = teams.teams.find(team => team.slug === TEAM_SLUG)
  if (team == null) {
    throw new Error(`Team not found: ${TEAM_SLUG}`)
  }
  return team.id
}

async function getDnsRecord(teamId: string) {
  const response = await vercel.dns.getRecords({
    domain: DOMAIN,
    teamId,
    limit: "100"
  })
  if (typeof response === 'string') {
    throw new Error(`Unknown DNS query response: ${response}`)
  }
  const records = response.records.filter(record => record.type === 'A' && record.name === 'bitcoin')
  const record = records[0]
  if (records.length > 1) {
    throw new Error(`Found ${records.length} DNS records for bitcoin.generatord.io. Expected 0 or 1.`)
  }
  return record
}

async function getIpAddress() {
  const { stdout } = await exec('kubectl get svc -o json')
  const services = K8S_SERVICE_SCHEMA.parse(JSON.parse(stdout))
  const ips = new Set(services.items.flatMap(item => item.status.loadBalancer.ingress?.map(({ ip }) => ip) ?? []))
  const ip = Array.from(ips)[0]
  if (ips.size !== 1 || ip == null) {
    throw new Error(`Expected exactly one IP address. Found: [${Array.from(ips).join(', ')}]`)
  }
  return ip
}
