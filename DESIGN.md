# onkofizjo — Stitch design system

This is the approved visual foundation for the onkofizjo ecosystem, derived from the exported Stitch project in `assets/stitch_onkofizjo_marketing_crm_interfaces.zip`.

## Product character

Boutique clinical minimalism: calm, private, editorial and clinically precise. The visual language must communicate intimacy, authority, continuity and premium care without becoming a generic wellness or SaaS template.

Core statement:

> Nie jesteś kolejnym terminem.

## Tokens

```css
--surface: #fdf9f5;
--surface-container: #f1ede9;
--clinical-white: #ffffff;
--ink: #0d1410;
--on-surface: #1c1c19;
--on-surface-variant: #424843;
--primary: #051a0f;
--primary-container: #1a2f23;
--on-primary-container: #809787;
--secondary: #79564f;
--secondary-container: #ffcfc7;
--sand: #d9d1c7;
--gold-leaf: #bd9b60;
--success-muted: #4f6f52;
--warning-muted: #e29578;
```


## Typography

- Literata: marketing headlines, section titles, quotes and emotional brand messaging.
- Inter: CRM navigation, clinical data, labels, forms and instructions.
- Display XL: 64/72.
- Display LG: 48/56.
- Headline MD: 32/40.
- Headline MD mobile: 28/36.
- Body LG: 18/28.
- Body MD: 16/24.
- Clinical data: 14/20, medium.
- Label caps: 12/16, bold, 8% tracking.

## Layout rules

- Marketing: wide asymmetrical margins, editorial rhythm, generous negative space.
- CRM: structured 12-column desktop grid and mobile-first task flow.
- Desktop container: 1280px maximum width.
- Desktop margin: 64px.
- Mobile margin: 16px.
- Base spacing unit: 8px.
- Section padding: 120px on desktop.

## Interaction rules

- Use tonal layering and fine borders instead of heavy shadows.
- Use contextual drawers on desktop and bottom sheets on mobile.
- Keep the current task visible while details expand.
- Use stepper states for meal plans: Draft → Assistant Proposed → Reviewed → Approved → Sent → Archived.
- AI cards always expose sources, rules, patient data used, confidence, uncertainty and approval status.
- Never let an AI proposal appear as an approved clinical decision.

## Care ecosystem colors

- Oncology rehabilitation: deep forest green.
- Dietetics: powder rose.
- Massage: muted sand.
- Home visits: restrained gold.
- Administrative states: neutral ink and cream.

## Reference screens in the Stitch export

- Marketing home.
- Services.
- Locations and contact.
- CRM desktop dashboard.
- CRM mobile home.
- Patient profile.
- Desktop meal-plan builder.
- Meal-plan PDF preview.
- Hermes AI workspace.
- Documentation center.
- Mobile documentation.
- Knowledge and blog.
- Login.

## Implementation boundary

Stitch is the visual and interaction reference, not the production backend. The generated HTML is treated as a prototype. Production code must replace mock data with typed domain models, authentication, persistence, permissions, audit events and human approval workflows.
