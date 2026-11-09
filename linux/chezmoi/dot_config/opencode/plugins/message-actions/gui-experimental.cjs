const { Plugin, Style } = require("@opencode/plugin/gui")

const actionsCss = String.raw`
/* Put user-message actions in their own row below the bubble. */
[data-component="user-message"] .oc-inline-actions-row {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  height: 20px;
  margin-top: 4px;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.12s ease-out;
}

[data-component="user-message"]:hover .oc-inline-actions-row,
[data-component="user-message"]:has(:focus-visible) .oc-inline-actions-row {
  opacity: 1;
  pointer-events: auto;
}

[data-component="user-message"] .oc-inline-actions {
  display: inline-flex;
  align-items: center;
  gap: 2px;
}

[data-component="user-message"] .oc-inline-action {
  width: 20px;
  height: 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: none;
  padding: 0;
  border: 0;
  border-radius: 4px;
  background: transparent;
  color: var(--v2-text-text-muted, #8b8b8b);
  cursor: pointer;
}

[data-component="user-message"] .oc-inline-action:hover {
  background: var(--v2-background-bg-layer-03, #3a3a3a);
  color: var(--v2-text-text-base, #eeeeee);
}

[data-component="user-message"] .oc-inline-action:disabled {
  opacity: 0.4;
  cursor: default;
}

[data-component="user-message"] .oc-inline-action svg {
  pointer-events: none;
}
`

const inlineActionsScript = String.raw`
(() => {
  const version = 3
  if (window.__ocInlineActionsVersion === version) return
  const legacy = window.__ocInlineActionsInstalled === true
  window.__ocInlineActionsInstalled = true
  window.__ocInlineActionsVersion = version

  const icons = {
    undo: '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 14 4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/></svg>',
    fork: '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="6" cy="5" r="2.5"/><circle cx="18" cy="5" r="2.5"/><circle cx="12" cy="19" r="2.5"/><path d="M6 7.5v2A4.5 4.5 0 0 0 10.5 14h3A4.5 4.5 0 0 0 18 9.5v-2"/><path d="M12 14v2.5"/></svg>',
    copy: '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>',
  }

  const titles = {
    undo: 'Undo message',
    fork: 'Fork from here',
    copy: 'Copy message',
  }

  const waitFor = (read, timeout) => new Promise((resolve) => {
    const started = Date.now()
    const tick = () => {
      const value = read()
      if (value) return resolve(value)
      if (Date.now() - started > timeout) return resolve(null)
      setTimeout(tick, 20)
    }
    tick()
  })

  const items = () => Array.from(document.querySelectorAll('[role="menuitem"]'))

  const triggerFor = (message) => {
    const wrapper = message.querySelector('[data-slot="user-message-menu"]')
    if (!wrapper) return null
    for (const button of wrapper.querySelectorAll('button')) {
      if (!button.closest('.oc-inline-actions')) return button
    }
    return null
  }

  const openMenu = async (trigger) => {
    if (items().length) return items()
    trigger.dispatchEvent(new PointerEvent('pointerdown', {
      bubbles: true,
      cancelable: true,
      button: 0,
      pointerId: 1,
      pointerType: 'mouse',
      isPrimary: true,
    }))
    const opened = await waitFor(() => items().length ? items() : null, 150)
    if (opened) return opened
    trigger.click()
    return await waitFor(() => items().length ? items() : null, 800)
  }

  const pressItem = (item) => {
    const options = {
      bubbles: true,
      cancelable: true,
      button: 0,
      pointerId: 1,
      pointerType: 'mouse',
      isPrimary: true,
    }
    item.dispatchEvent(new PointerEvent('pointerdown', options))
    item.dispatchEvent(new PointerEvent('pointerup', options))
  }

  const run = async (message, matcher) => {
    const trigger = triggerFor(message)
    if (!trigger) return
    const available = await openMenu(trigger)
    if (!available || !available.length) return
    const item = available.find((candidate) => matcher.test((candidate.textContent || '').trim()))
    if (item && item.getAttribute('aria-disabled') !== 'true' && !item.hasAttribute('data-disabled')) {
      pressItem(item)
      return
    }
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', code: 'Escape', bubbles: true }))
  }

  const add = (message) => {
    const menu = message.querySelector('[data-slot="user-message-menu"]')
    if (legacy && menu) {
      for (const old of menu.querySelectorAll(':scope > .oc-inline-actions')) old.remove()
      if (!menu.querySelector(':scope > .oc-inline-actions')) {
        const marker = document.createElement('span')
        marker.className = 'oc-inline-actions oc-inline-actions-marker'
        marker.hidden = true
        menu.prepend(marker)
      }
    }

    const body = message.querySelector('[data-slot="user-message-body"]')
    const host = body ?? message
    if (host.querySelector(':scope > .oc-inline-actions-row')) return

    const pending = message.hasAttribute('data-pending')
    const actions = document.createElement('span')
    actions.className = 'oc-inline-actions'

    const make = (kind, matcher) => {
      const button = document.createElement('button')
      button.type = 'button'
      button.className = 'oc-inline-action'
      button.title = titles[kind]
      button.setAttribute('aria-label', titles[kind])
      button.innerHTML = icons[kind]
      button.addEventListener('mousedown', (event) => event.preventDefault())
      button.addEventListener('click', (event) => {
        event.preventDefault()
        event.stopPropagation()
        void run(message, matcher)
      })
      if (pending && kind !== 'copy') button.style.display = 'none'
      return button
    }

    actions.append(
      make('undo', /^(undo|revert to here)$/i),
      make('fork', /^fork from here$/i),
      make('copy', /^copy message$/i),
    )

    const row = document.createElement('div')
    row.className = 'oc-inline-actions-row'
    row.append(actions)
    host.append(row)
  }

  const scan = () => document.querySelectorAll('[data-component="user-message"]').forEach(add)

  let scheduled = false
  const schedule = () => {
    if (scheduled) return
    scheduled = true
    requestAnimationFrame(() => {
      scheduled = false
      scan()
    })
  }

  new MutationObserver(schedule).observe(document.documentElement, { childList: true, subtree: true })
  scan()
})()
`

module.exports = Plugin.define({
  setup(ctx) {
    ctx.add(Style, actionsCss)
  },
  main(ctx) {
    const cleanups = []
    const attach = (window) => {
      const inject = async () => {
        try {
          const installed = await window.webContents.executeJavaScript('window.__ocInlineActionsVersion ?? 0')
          if (installed !== 0 && installed !== 3) {
            window.webContents.reload()
            return
          }
          await window.webContents.executeJavaScript(inlineActionsScript)
        } catch (error) {
          ctx.log.write("warn", `message-actions: inline message actions injection failed: ${error}`)
        }
      }
      window.webContents.on('did-finish-load', inject)
      if (!window.webContents.isLoading()) inject()
      const remove = () => window.webContents.removeListener('did-finish-load', inject)
      cleanups.push(remove)
      window.once('closed', remove)
    }
    ctx.windows.list().forEach(attach)
    const off = ctx.windows.on('open', attach)
    return () => {
      off()
      for (const remove of cleanups) remove()
    }
  },
})
