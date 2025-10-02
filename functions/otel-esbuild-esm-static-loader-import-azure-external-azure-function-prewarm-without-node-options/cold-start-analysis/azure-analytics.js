import fs from 'node:fs'
import { DefaultAzureCredential } from '@azure/identity';
import { LogsQueryClient, LogsQueryResultStatus } from '@azure/monitor-query-logs';

const workspaceId = '2499370b-ccf7-4bb3-a500-8094765dc62c'; // Replace with your App Insights Workspace ID

async function fetchAzureDuration(operationId) {
  const credential = new DefaultAzureCredential();
  const client = new LogsQueryClient(credential);

  try {
    const past = new Date()
    past.setDate(past.getDate() - 5);
    const kqlQuery = `AppRequests | where OperationId == "${operationId}" | project DurationMs`;
    const result = await client.queryWorkspace(workspaceId, kqlQuery, {
      startTime: past,
      endTime: new Date()
    });

    if (result.status === LogsQueryResultStatus.Success) {
      const table = result.tables[0];
      // Print rows
      return table.rows[0][0]; // Return the DurationMs value]
    } else {
      console.error('Query failed:', result.partialError);
    }
  } catch (err) {
    console.error('Error querying Application Insights:', err);
  }
}

async function main() {
  // replace with with file path with arguments
  const filename = process.argv[2]
  if (!filename || !fs.existsSync(filename)) {
    console.error('Please provide a valid file path as an argument.')
    process.exit(1)
  }
  const content = fs.readFileSync(filename)

  const data = []
  for (const line of content.toString().split('\n')) {
    if (line.trim() === '') continue
    const time = line.substring(0, 28)
    const trace = line.substring(63, 95)
    const wallDuration = line.substring(117, 126)
    const azureDurationMs = await fetchAzureDuration(trace)
    const azureDurationSeconds = (azureDurationMs / 1000).toFixed(6)
    const diffDuration = (parseFloat(wallDuration) - parseFloat(azureDurationSeconds)).toFixed(6)
    // these are not cold starts so skip them
    if (diffDuration < 0.20) {
      console.warn('Skipping entry with diff < 1s:', { time, trace, wallDuration, azureDuration: azureDurationSeconds, diffDuration })
    }
    data.push({ time, trace, wallDuration, azureDuration: azureDurationSeconds, diffDuration })
    console.log('Time:', time, ' Trace:', trace, ' Wall Duration:', wallDuration, ' Azure Duration:', azureDurationSeconds, ' Diff:', diffDuration)
  }


  const tableHeader = '|Time                       | Trace                               | Wall Duration | Azure Duration | Diff Duration|\n' +
    '|--------------------------|-------------------------------------|---------------|----------------|---------------|\n'
  const table = data.map(d => `| ${d.time} | ${d.trace} | ${d.wallDuration} | ${d.azureDuration} | ${d.diffDuration} |`).join('\n')

  const fileContent = tableHeader + table + '\n'
  fs.writeFileSync(filename.replace('log', 'md'), fileContent, {})
}

await main();
