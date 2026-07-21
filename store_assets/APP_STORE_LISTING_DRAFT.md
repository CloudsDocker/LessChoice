# App Store listing draft — SelectLess

Edit freely before pasting into App Store Connect. Character limits noted.

## App name (30 char max)
SelectLess

## Subtitle (30 char max)
Swipe to your next trip idea

## Promotional text (170 char max, editable without new review)
Stuck picking a destination or activity? Swipe through AI-curated ideas, keep what you like, and get a focused shortlist in minutes.

## Description (4000 char max)

SelectLess turns "I don't know what to pick" into a calm, guided decision.

Tell it what you're deciding — a weekend trip, a night out, anything with
too many options — and swipe through a deck of real, specific suggestions
with photos. Keep the ones you like, mark others as "maybe," and discard
the rest. The more you swipe, the better the suggestions get: SelectLess
learns your taste as you go and steers away from what you've already
passed on.

FEATURES

• Real place suggestions with real photos, not generic stock lists
• Local-language names and descriptions alongside English
• Keeps refining suggestions based on what you keep, discard, or mark maybe
• Build a shortlist you can revisit, save as an image, or share as a PDF
• No account required — just open it and start deciding

HOW IT WORKS

1. Describe what you're deciding and any constraints (budget, time, mood)
2. Swipe through suggestions: Yes, No, or Maybe
3. Watch your shortlist build itself as you go
4. Review, save, or share your final picks

SelectLess doesn't require sign-in, doesn't track you, and doesn't collect
personal data — see our Privacy Policy for details.

## Keywords (100 char max, comma-separated, no spaces after commas)
decision,swipe,trip planner,travel ideas,choices,decide,shortlist,indecisive,suggestions,ai

## Support URL
(needs a real page — even a single static page with an email/contact is enough. Suggest: a GitHub Pages page on the LessChoice repo, e.g. https://cloudsdocker.github.io/LessChoice/support.html)

## Marketing URL (optional)
(same as above, or leave blank)

## Privacy Policy URL
See PRIVACY_POLICY.md in this folder — publish it somewhere with a stable
URL (GitHub Pages is the easiest free option since the repo is already on
GitHub) and paste that URL into App Store Connect's Privacy Policy field.

## App Privacy questionnaire (App Store Connect → App Privacy)
Based on what the app actually does (no accounts, no location, no
analytics/tracking SDKs, no advertising):

- Data collected: **None** that's linked to the user's identity.
- The app sends free-text prompts/constraints you type to a backend server,
  which forwards them to Google's Gemini API to generate suggestions, and
  place names to Google Places API to fetch photos. This is functionally
  necessary data, not linked to an identifiable user, and not used for
  tracking.
- Answer "No" to "Do you or your third-party partners collect data from
  this app?" if you're confident none of the above counts as linked
  personal data under Apple's definitions — otherwise declare "User
  Content" (the text prompts) as collected but "not linked to identity"
  and "not used for tracking."
