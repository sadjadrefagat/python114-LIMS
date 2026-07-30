import { useCallback, useRef, useState } from 'react'
import ConfirmDialog from '../components/ConfirmDialog'

/**
 * ask(options) → Promise<boolean>
 * options: { title, message, details, confirmLabel, cancelLabel, tone }
 */
export function useConfirmDialog() {
  const [options, setOptions] = useState(null)
  const resolveRef = useRef(null)

  const ask = useCallback((opts) => {
    return new Promise((resolve) => {
      resolveRef.current = resolve
      setOptions(opts || {})
    })
  }, [])

  const finish = useCallback((result) => {
    const resolve = resolveRef.current
    resolveRef.current = null
    setOptions(null)
    resolve?.(result)
  }, [])

  const dialog = (
    <ConfirmDialog
      open={Boolean(options)}
      title={options?.title}
      message={options?.message}
      details={options?.details}
      confirmLabel={options?.confirmLabel}
      cancelLabel={options?.cancelLabel}
      tone={options?.tone}
      onConfirm={() => finish(true)}
      onCancel={() => finish(false)}
    />
  )

  return [ask, dialog]
}
