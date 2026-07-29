# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

"Cuadre" is a single-file, static personal finance web app (Spanish UI). There is no build system, package manager, bundler, or test suite — the entire application (markup, CSS, and JS) lives in `index.html`. There is no server-side code.

## Development

- There are no build/lint/test commands — this project has no `package.json`, no dependencies, and no tooling. Just edit `index.html` directly.
- To preview changes, open `index.html` directly in a browser, or serve it locally (e.g. `python -m http.server`) if `file://` restrictions cause issues with `window.storage`.
- There is no automated test suite. Verify changes manually in a browser.

## Architecture

Everything lives in `index.html`, structured as:
1. `<style>` block — CSS custom properties (in `:root`) define the color palette/theme; component styles follow (cards, chips, modals/"sheets", calendar, sliders).
2. HTML body — the main screen (balance, "saldo relativo" tile, movement list) plus three modal overlays: the add/edit movement sheet (`#overlay`), the "saldo relativo" / credit card payment planner (`#cardsOverlay`), and the credit card create/edit form (`#cardFormOverlay`).
3. A single IIFE `<script>` at the bottom containing all app logic.

### State model

All app data lives in one in-memory `state` object:
```js
state = {
  categories: [...],       // string[] of expense/income categories
  movements: [],           // {id, category, amount, type: "expense"|"income", date: "YYYY-MM-DD", createdAt}
  creditCards: []          // {id, name, totalDebt, cutDay, dueDay, minPercent, minPayment, paymentAmount}
}
```
- Persistence is via `window.storage.get/set(STORAGE_KEY, ...)` (`STORAGE_KEY = "cuadre-data"`), an injected host API — not `localStorage`. The whole `state` object is JSON-serialized on every save (`saveData()`) and reloaded on startup (`loadData()`).
- `render()` is the top-level re-render entry point, fanning out to `renderBalance`, `renderList`, `renderRelativeTile`, and `renderPinnedCards`. Call `render()` (or the specific sub-renderer) after any state mutation — there is no reactive framework, so nothing re-renders automatically.

### Key concepts

- **Saldo total** (`renderBalance`): sum of all movements minus total credit card debt (`computeMovementsBalance() - computeCardsDebtTotal()`).
- **Saldo relativo** (`renderRelativeTile`, and the "Saldo relativo" sheet): a what-if simulator — movements balance minus the *currently selected* payment amount per card (via sliders/"knobs" in `cardsOverlay`), not the full debt. Each card's payment defaults to its computed minimum (`getMinPayment`) until the user drags its knob, which sets `paymentAmount`.
- **Credit cards as a special "category"**: the modal's category chip row includes a hardcoded `💳 Tarjeta de crédito` chip that doesn't create a movement — it closes the add/edit sheet and opens the card form (`openCardForm`) instead.
- **Future-dated movements**: any movement with `date > todayStr()` is tagged "Programado" in the list and still counts toward balances (nothing is excluded for being in the future).
- Dates are plain `YYYY-MM-DD` strings throughout (`todayStr`, `parseDate`, `dateToStr`, `fmtDateHuman`); avoid introducing `Date` objects into state — keep persisted dates as strings.
- Two independent custom calendar widgets exist: one for picking a movement date (`renderCalendar`/`#calGrid`), and one read-only "reminder" calendar in the cards sheet that highlights the day 3 days before each card's due date (`renderCardsCalendar`/`#cardsCalGrid`). They are separate implementations, not shared code.
- User-provided strings (category names, card names) are rendered via `escapeHtml()` before being interpolated into `innerHTML` — keep doing this for any new user input rendered into the DOM.
