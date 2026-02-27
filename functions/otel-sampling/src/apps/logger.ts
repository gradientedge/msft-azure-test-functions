import { SeverityNumber, logs, type LogBody, type LogRecord } from '@opentelemetry/api-logs'
import { context, type HrTime } from '@opentelemetry/api'

export function dateToOtelHrTime(date: Date): HrTime {
  const now = date.getTime()
  const sinceUnixEpoch = Math.trunc(now / 1000)
  const nanosAfterSinceUnixEpoch = Number((now - sinceUnixEpoch * 1000).toFixed(9)) * 1e6
  return [sinceUnixEpoch, nanosAfterSinceUnixEpoch]
}

export function nodeHRTimeToOtelHrTime(date: Date, time: bigint): HrTime {
  const dateTime = date.getTime()
  const sinceUnixEpoch = Math.trunc(dateTime / 1000)
  const withoutMillis = sinceUnixEpoch * 1000
  const nano = (BigInt(dateTime) - BigInt(withoutMillis)) * 1_000_000n + (time % 1_000_000n)
  return [Number(sinceUnixEpoch), Number(nano)]
}

export const LoggerLevel = {
  DEBUG: 'DEBUG',
  INFO: 'INFO',
  WARN: 'WARN',
  ERROR: 'ERROR',
} as const

type LoggerLevelType = keyof typeof LoggerLevel

export type LoggerLevelValue = (typeof LoggerLevel)[keyof typeof LoggerLevel]
export interface LoggerTransportFn {
  (...args: any[]): any
}

export type LoggerTransport = {
  [key in Lowercase<LoggerLevelValue>]: LoggerTransportFn
}

export const logger: LoggerTransport = {
  debug: (...args: any[]): void => logRecord(LoggerLevel.DEBUG, SeverityNumber.DEBUG, args),
  info: (...args: any[]): void => logRecord(LoggerLevel.INFO, SeverityNumber.INFO, args),
  warn: (...args: any[]): void => logRecord(LoggerLevel.WARN, SeverityNumber.WARN, args),
  error: (...args: any[]): void => logRecord(LoggerLevel.ERROR, SeverityNumber.ERROR, args),
}

function logRecord(severityText: LoggerLevelType, severityNumber: number, ...args: any[]): void {
  const ctx = context.active()
  const logData = args[0]?.[0]
  const timestamp = nodeHRTimeToOtelHrTime(new Date(), process.hrtime.bigint())
  const observedTimestamp = dateToOtelHrTime(new Date(logData.timestamp))
  const body: LogBody = String(logData.message)
  const logRec: LogRecord = {
    timestamp,
    observedTimestamp,
    context: ctx,
    severityText,
    severityNumber,
    body,
    attributes: {
      'log.type': 'LogRecord',
      ...logData.data,
      base: logData.base,
    },
  }
  const logger = logs.getLogger('default')
  logger.emit(logRec)
}
