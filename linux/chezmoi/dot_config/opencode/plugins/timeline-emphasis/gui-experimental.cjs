const { Plugin, Style } = require("@opencode/plugin/gui")

const css = String.raw`
/* Conversation first: make user messages and assistant prose read as messages,
   and keep tool output/shell output visible but visually quieter. */

/* User messages: refined bubble with a sent-message accent rail. */
:root body [data-component="user-message"]:not([data-pending]) [data-slot="user-message-text"] {
  padding: 10px 14px;
  border-radius: 14px;
  border-start-end-radius: calc(14px - 8px * var(--user-run-top, 0));
  border-end-end-radius: calc(14px - 8px * var(--user-run-bottom, 0));
  background:
    linear-gradient(
      180deg,
      color-mix(in oklab, var(--v2-text-text-accent, #6b9eff) 13%, var(--v2-background-bg-layer-02, #1c1c1c)) 0%,
      color-mix(in oklab, var(--v2-text-text-accent, #6b9eff) 6%, var(--v2-background-bg-layer-02, #1c1c1c)) 100%
    );
  border: 1px solid color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 28%,
    transparent
  );
  border-inline-end: 3px solid color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 62%,
    transparent
  );
  box-shadow:
    inset 0 1px 0 color-mix(in oklab, #ffffff 9%, transparent),
    0 2px 12px color-mix(
      in oklab,
      var(--v2-text-text-accent, #6b9eff) 10%,
      transparent
    );
  transition:
    background-color .15s ease-out,
    color .15s ease-out,
    border-color .15s ease-out,
    box-shadow .15s ease-out,
    transform .15s ease-out;
}

:root body [data-component="user-message"]:not([data-pending]):hover [data-slot="user-message-text"],
:root body [data-component="user-message"]:not([data-pending]):focus-within [data-slot="user-message-text"] {
  border-color: color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 42%,
    transparent
  );
  border-inline-end-color: color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 82%,
    transparent
  );
  box-shadow:
    inset 0 1px 0 color-mix(in oklab, #ffffff 12%, transparent),
    0 5px 20px color-mix(
      in oklab,
      var(--v2-text-text-accent, #6b9eff) 18%,
      transparent
    );
  transform: translateY(-1px);
}

:root body [data-component="user-message"][data-pending] [data-slot="user-message-text"] {
  padding: 10px 14px;
  border-radius: 14px;
  background: color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 5%,
    var(--v2-background-bg-layer-01, #242424)
  );
  border: 1px dashed color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 32%,
    transparent
  );
  color: var(--v2-text-text-muted, #aeaeae);
  box-shadow: none;
}

:root body [data-component="user-message"] [data-slot="user-message-attachment"] {
  border-color: color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 26%,
    var(--v2-border-border-base, #ffffff1a)
  );
  box-shadow: 0 1px 8px color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 8%,
    transparent
  );
}

/* Keep the existing hover meta/actions, but fade them in. */
[data-component="user-message"] [data-slot="user-message-copy-wrapper"] {
  transition: opacity .15s ease-out;
}

/* Assistant prose: a card with an accent rule, instead of another log line.
   It stops short of the conversation column's right edge; user messages still
   right-align to the column edge. */
[data-component="text-part"] {
  max-width: 95%;
  box-sizing: border-box;
  padding: 10px 16px;
  border-inline-start: 3px solid color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 55%,
    transparent
  );
  border-radius: 10px;
  background: color-mix(
    in oklab,
    var(--v2-background-bg-layer-02, #1c1c1c) 55%,
    transparent
  );
}

[data-component="text-part"] [data-slot="text-part-body"] {
  margin-top: 0;
}

/* Tool calls, shell output, edits and reasoning: still there, but quiet. */
[data-timeline-row="AssistantPart"]:not(:has([data-component="text-part"])),
[data-timeline-row="Shell"],
[data-timeline-row="Thinking"] {
  opacity: 0.55;
  transition: opacity 120ms ease-out;
}

[data-timeline-row="AssistantPart"]:not(:has([data-component="text-part"])):hover,
[data-timeline-row="Shell"]:hover,
[data-timeline-row="Thinking"]:hover {
  opacity: 1;
}

/* Subagent buttons stay prominent and get the same accent treatment. */
:root body [data-timeline-row="AssistantPart"]:has(.subagent-link),
:root body [data-timeline-row="AssistantPart"]:has([data-component="task-tool-card"]) {
  opacity: 1;
}

:root body [data-component="tool-part-wrapper"]:has(.subagent-link) [data-slot="collapsible-trigger"] {
  background: color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 8%,
    transparent
  );
  border: 1px solid color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 24%,
    transparent
  );
  border-radius: 8px;
}

:root body [data-component="tool-trigger"] [data-slot="basic-tool-tool-subtitle"].subagent-link {
  background: color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 14%,
    transparent
  );
  border: 1px solid color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 32%,
    transparent
  );
  border-radius: 999px;
  padding: 0 7px;
}

:root body [data-component="task-tool-card"] [data-component="task-tool-surface"] {
  background: color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 8%,
    var(--v2-background-bg-layer-02, #2e2e2e)
  );
  border: 1px solid color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 26%,
    transparent
  );
  border-inline-start: 3px solid color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 55%,
    transparent
  );
  border-radius: 8px;
}

:root body [data-component="task-tool-card"]:hover [data-component="task-tool-surface"],
:root body [data-component="task-tool-card"]:focus-visible [data-component="task-tool-surface"] {
  background: color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 12%,
    var(--v2-background-bg-layer-02, #2e2e2e)
  );
  border-color: color-mix(
    in oklab,
    var(--v2-text-text-accent, #6b9eff) 42%,
    transparent
  );
}

/* Never bury errors. */
[data-timeline-row="Error"],
[data-timeline-row="AssistantPart"]:has([data-component="tool-error-card"]) {
  opacity: 1;
}
`

module.exports = Plugin.define({
  setup(ctx) {
    ctx.add(Style, css)
  },
})
