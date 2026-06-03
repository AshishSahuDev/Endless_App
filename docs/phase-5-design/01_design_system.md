# Design System & Style Guide
**Project:** Endless App | **Version:** 1.0 | **Date:** 2026-06-03 | **Author:** Ashish Sahu

---

## 1. Design Philosophy

- **Dark First** — Dark mode is default. Feels premium, saves battery on OLED screens
- **Alive** — Every interaction has a micro-animation. Nothing is static
- **Instant** — Zero loading spinners for local operations. Data appears immediately
- **Generous** — Large touch targets, readable text, breathing room in layouts
- **Gen-Z Aesthetic** — Glassmorphism, gradients, neon accents. Not flat. Not boring

---

## 2. Color Palette

### Dark Mode (Default)

| Token | Hex | Usage |
|---|---|---|
| `colorBg` | `#0A0A0F` | Main app background |
| `colorSurface` | `#12121A` | Card backgrounds, bottom sheets |
| `colorSurfaceVariant` | `#1A1A28` | Input fields, secondary cards |
| `colorPurple` | `#7C3AED` | Primary accent, CTAs, active states |
| `colorPurpleLight` | `#A78BFA` | Purple on dark surfaces, secondary text accents |
| `colorPink` | `#EC4899` | Secondary accent, high-priority badges |
| `colorBlue` | `#3B82F6` | Info states, links, medium-priority |
| `colorGreen` | `#10B981` | Income, success states, low-priority |
| `colorRed` | `#EF4444` | Expenses, errors, delete actions |
| `colorOrange` | `#F59E0B` | Warnings, budget 80% alerts |
| `colorTextPrimary` | `#FFFFFF` | Main text |
| `colorTextSecondary` | `#94A3B8` | Subtitles, metadata, placeholder |
| `colorTextDisabled` | `#475569` | Disabled elements |
| `colorBorder` | `rgba(255,255,255,0.08)` | Card borders, dividers |
| `colorGlass` | `rgba(255,255,255,0.05)` | Glassmorphism fill |
| `colorOverlay` | `rgba(0,0,0,0.6)` | Modal backdrops, bottom sheet overlay |

### Light Mode

| Token | Hex | Usage |
|---|---|---|
| `colorBg` | `#F8FAFF` | Main background |
| `colorSurface` | `#FFFFFF` | Cards |
| `colorSurfaceVariant` | `#F1F5FF` | Input fields |
| `colorPurple` | `#7C3AED` | Same primary accent |
| `colorPink` | `#EC4899` | Same secondary accent |
| `colorTextPrimary` | `#0F172A` | Main text |
| `colorTextSecondary` | `#64748B` | Subtitles |
| `colorBorder` | `rgba(0,0,0,0.08)` | Borders |

### Gradients

```dart
// Primary gradient (purple → blue)
LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)])

// Secondary gradient (pink → purple)
LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF7C3AED)])

// Money income gradient (green → blue)
LinearGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6)])

// Money expense gradient (red → pink)
LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFEC4899)])

// Glassmorphism overlay
LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [rgba(255,255,255,0.12), rgba(255,255,255,0.04)])
```

### Note Color Palette (8 colors)
```
0 = Default (surface color)
1 = Rose     #FEE2E2
2 = Orange   #FEF3C7
3 = Yellow   #FEF9C3
4 = Green    #D1FAE5
5 = Blue     #DBEAFE
6 = Purple   #EDE9FE
7 = Pink     #FCE7F3
```
(In dark mode: reduce opacity to 30% for note color fill)

---

## 3. Typography

**Font Families:**
- **UI:** `Sora` (preferred) or `Plus Jakarta Sans` (fallback) — via google_fonts
- **Numbers/Money:** `Space Grotesk` — tabular numbers look great for amounts
- **Monospace:** `Fira Code` — for any code snippets in notes

### Type Scale

| Name | Font | Size | Weight | Line Height | Usage |
|---|---|---|---|---|---|
| `displayLarge` | Sora | 32sp | 700 | 1.2 | Onboarding headings |
| `headlineLarge` | Sora | 24sp | 700 | 1.3 | Screen titles |
| `headlineMedium` | Sora | 20sp | 600 | 1.3 | Section headings |
| `titleLarge` | Sora | 18sp | 600 | 1.4 | Card titles, list headers |
| `titleMedium` | Sora | 16sp | 500 | 1.4 | Bottom nav labels |
| `bodyLarge` | Sora | 16sp | 400 | 1.6 | Primary body text |
| `bodyMedium` | Sora | 14sp | 400 | 1.5 | Secondary body, descriptions |
| `labelLarge` | Sora | 14sp | 600 | 1.4 | Buttons, chips, tabs |
| `labelSmall` | Sora | 12sp | 500 | 1.4 | Metadata, timestamps, badges |
| `moneyLarge` | Space Grotesk | 32sp | 700 | 1.2 | Balance display |
| `moneyMedium` | Space Grotesk | 22sp | 600 | 1.3 | Transaction amounts |
| `moneySmall` | Space Grotesk | 16sp | 500 | 1.4 | Budget figures |

---

## 4. Spacing System

Base unit: **4dp**

| Token | Value | Usage |
|---|---|---|
| `space1` | 4dp | Micro gaps, icon padding |
| `space2` | 8dp | Tight spacing, small padding |
| `space3` | 12dp | Component internal padding |
| `space4` | 16dp | Standard padding, list item gaps |
| `space5` | 20dp | Section padding |
| `space6` | 24dp | Card padding |
| `space8` | 32dp | Large section gaps |
| `space10` | 40dp | Hero section padding |
| `space12` | 48dp | Screen top padding |
| `space16` | 64dp | Major section separation |

---

## 5. Border Radius

| Token | Value | Usage |
|---|---|---|
| `radiusXS` | 4dp | Chips, small tags |
| `radiusSM` | 8dp | Input fields, small cards |
| `radiusMD` | 12dp | Standard cards |
| `radiusLG` | 16dp | Bottom sheets, large cards |
| `radiusXL` | 24dp | Modal dialogs |
| `radiusPill` | 999dp | Buttons, badges |

---

## 6. Component Specifications

### Primary Button
```
Height:        56dp
Border radius: 28dp (pill)
Background:    LinearGradient(purple → blue), begin: topLeft
Padding:       horizontal 24dp
Text:          labelLarge, white
Shadow:        0 4 20 rgba(124,58,237,0.4)

States:
  Default:  opacity 1.0, shadow active
  Pressed:  scale 0.97 (spring animation 150ms)
  Disabled: opacity 0.4, no shadow, no gradient (flat surface)
  Loading:  replace text with CircularProgressIndicator (white, 20dp)
```

### Ghost Button
```
Height:        56dp
Border radius: 28dp
Border:        1.5dp solid rgba(255,255,255,0.2)
Background:    transparent
Text:          labelLarge, colorTextPrimary
Pressed:       background rgba(255,255,255,0.06)
```

### Floating Action Button (FAB)
```
Size:          60dp × 60dp
Border radius: 30dp
Background:    LinearGradient(pink → purple)
Icon:          24dp, white
Shadow:        0 8 24 rgba(124,58,237,0.5)
Animation:     rotateZ(45deg) on expand → morph to bottom sheet
```

### Glassmorphism Card
```
Background:    rgba(255,255,255,0.05)
Blur:          BackdropFilter blur(20dp)
Border:        1dp solid rgba(255,255,255,0.08)
Border radius: radiusLG (16dp)
Shadow:        none (glass doesn't need drop shadow)
Hover/focus:   border color → rgba(124,58,237,0.4)
```

### Bottom Navigation Bar
```
Height:        72dp
Background:    rgba(10,10,15,0.95) + BackdropFilter blur(20dp)
Border top:    0.5dp solid rgba(255,255,255,0.06)
Item:          icon 24dp + label 10sp, spacing 4dp
Active item:   pill background rgba(124,58,237,0.2), icon purple, label purple
Pill:          height 32dp, auto-width, radius 16dp
Pill animation: AnimatedContainer, 200ms ease-in-out slide
```

### Input Field
```
Height:        56dp
Background:    colorSurfaceVariant
Border:        1dp solid rgba(255,255,255,0.08)
Border radius: radiusMD (12dp)
Focus border:  1.5dp solid colorPurple + glow shadow rgba(124,58,237,0.3)
Label:         floating label, animates up on focus
Text:          bodyLarge, colorTextPrimary
Placeholder:   bodyLarge, colorTextDisabled
```

### Bottom Sheet
```
Background:    colorSurface
Border radius: radiusXL (24dp) top corners only
Drag handle:   4dp × 32dp, rounded, rgba(255,255,255,0.2), centered top
Max height:    80% of screen
Overlay:       colorOverlay, tap to dismiss
Enter anim:    slide up + fade, 300ms cubic-bezier(0.4,0,0.2,1)
Exit anim:     slide down, 250ms ease-in
```

### Progress Bar
```
Height:        8dp
Background:    rgba(255,255,255,0.08)
Fill:          LinearGradient(purple → blue) or red if >100%
Border radius: 4dp (pill)
Animation:     AnimatedContainer width change, 600ms easeOut
Glow:          box-shadow with fill color at 40% opacity
```

---

## 7. Animation Guidelines

| Type | Duration | Easing | Usage |
|---|---|---|---|
| Micro | 150ms | easeInOut | Button press, toggle switch |
| Standard | 250ms | cubic-bezier(0.4,0,0.2,1) | Page transitions, card expand |
| Entrance | 300ms | easeOut | New item appearing in list |
| Celebration | 1000ms+ | spring | Confetti, goal achieved |

**Rules:**
- Never animate more than 2 properties simultaneously (causes jank)
- Use `const` constructors for non-animated widgets to avoid rebuilds
- Stagger list item entrance by 50ms per item (max 5 items staggered, then batch)
- Page transitions: slide from right (push) + fade, 250ms

---

## 8. Priority Color System

| Priority | Color | Usage |
|---|---|---|
| High | `#EF4444` (red) | Task priority, urgent reminders |
| Medium | `#F59E0B` (amber) | Task priority, budget 80% alert |
| Low | `#10B981` (green) | Task priority, success states |
| None | `#64748B` (gray) | No priority set |

---

## 9. Icon System

**Package:** `iconsax` (Gen-Z style, consistent weight)
**Sizes:** 20dp (inline/small), 24dp (standard), 28dp (large/nav)
**Color:** Inherit from parent (use `IconTheme`)

Key icons mapping:
- Notes: `Iconsax.note_text`
- Tasks: `Iconsax.task_square`
- Reminders: `Iconsax.notification`
- Alarms: `Iconsax.clock`
- Money: `Iconsax.wallet`
- Add/FAB: `Iconsax.add`
- Search: `Iconsax.search_normal`
- Settings: `Iconsax.setting_2`
- Pin: `Iconsax.map_1`
- Archive: `Iconsax.archive`
- Delete: `Iconsax.trash`
- Edit: `Iconsax.edit_2`

---

## 10. Accessibility

- **Contrast:** All text meets WCAG AA minimum (4.5:1 for normal text, 3:1 for large)
- **Touch targets:** Minimum 44×44dp for all interactive elements
- **Semantic labels:** All icon buttons have `Semantics(label: '...')`
- **Screen reader:** All screens navigable with TalkBack (Android) enabled

---

*Document: 01_design_system.md | Phase 5 — Design*
