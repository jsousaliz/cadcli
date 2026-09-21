# LESSONS - auto-maintained by scripts/lessons.py

> Machine-owned. Do NOT hand-edit. Changes are overwritten on the next `lessons.py` write.
> Canonical state lives in `.specs/lessons.json`. Edit lessons only via the script.
> promote_threshold=2 distinct features · window_days=45 · quarantine_threshold=2

## Confirmed (load these at Plan/Checks)

Corroborated across multiple features. Safe to apply as guidance.

_none_

## Candidates (under observation - do NOT load as guidance yet)

Seen once or not yet corroborated. Tracked, not trusted.

### L-001 - Assert the observable output on the object the production path actually shows, not on a separately built instance from the same factory
- signal: `surviving_mutant` · recurrence: 1 feature(s) · scope: `visao-dialogos` · harmful: 0
- features: parte-02-form-principal
- evidence: src/Visao/Visao.ApresentadorErro.pas:38 (C27, round 2) (visao-dialogos)
- last seen: 2026-09-21T17:36:25Z

### L-002 - When a check names several properties of a displayed dialog, assert each property on the displayed instance
- signal: `ac_gap` · recurrence: 1 feature(s) · scope: `visao-dialogos` · harmful: 0
- features: parte-02-form-principal
- evidence: C27 - tests/Unitarios/Testes.FormPrincipal.pas:323,357 (visao-dialogos)
- last seen: 2026-09-21T17:36:26Z

## Quarantined (failed when applied - ignore)

A confirmed lesson that recurred alongside failure. Kept for the maintainer to review.

_none_
