# DecisionDeck

DecisionDeck is a polished SwiftUI iPhone app concept for reducing decision fatigue. The app presents options as swipe-style cards, lets the user keep or discard each one, and finishes with a shortlist of the choices that survived the rounds.

## deploy
https://claude.ai/code/artifact/365391ff-3ccc-473d-8b60-b434df6fa5ed?via=auto_preview


## What this version includes
- Clean onboarding and setup experience
- Card-based decision flow with keep/discard actions
- Results screen with a final shortlist
- Sample context for travel planning, such as Kuala Lumpur from Sydney

## How to open in Xcode
1. Open Xcode.
2. Choose File > Open.
3. Select the DecisionDeck folder.
4. Open the Xcode project file in the DecisionDeck.xcodeproj folder.
5. Choose a simulator such as iPhone 15 or a real iPhone connected by cable.
6. Press Run to launch the app.

## How to test it on your local Mac
### 1. Install prerequisites
- Install Xcode from the Mac App Store.
- Open Xcode and accept the license terms.
- Install the latest iOS simulator runtime from Xcode > Settings > Platforms.

### 2. Run the app locally
1. Open the project in Xcode.
2. Select the target device or simulator.
3. Press Cmd + R to build and run.
4. Test the main flow:
   - enter a decision prompt
   - add constraints
   - start the session
   - tap Keep or Discard on each card
   - confirm the final shortlist appears

### 3. Test on a real iPhone
1. Connect your iPhone with a cable.
2. Trust the computer on the iPhone if prompted.
3. In Xcode, choose your iPhone from the device list.
4. Run the app again.
5. Check the experience on actual device performance and gesture feel.

### 4. Basic quality checks
- Confirm the UI looks polished on both small and large iPhone screens.
- Make sure text remains readable and buttons are easy to tap.
- Test with a weak network connection if you later add web search or remote data.
- Check that the app does not crash when starting a new decision session.

## App Store publishing checklist
### 1. Prepare the app identity
- Choose a final app name and subtitle.
- Set a unique bundle identifier such as com.yourname.decisiondeck.
- Fill in app category, age rating, and privacy details.

### 2. Prepare assets
- Create a high-quality app icon in all required sizes.
- Prepare screenshots for iPhone 15, 15 Pro, and possibly older supported devices.
- Write an App Store description, keywords, and support URL.

### 3. Configure signing
1. In Xcode, select the target.
2. Go to Signing & Capabilities.
3. Select your Apple Developer Team.
4. Enable automatic signing or use manual signing if required.

### 4. Test before submission
- Run on multiple simulators and at least one real device.
- Verify the app works after a cold start and after restarting.
- Check that no crashes or obvious layout issues appear.
- Review content for clarity, grammar, and tone.

### 5. Submit to App Store Connect
1. Create an App Store Connect account and app record.
2. Upload the build from Xcode.
3. Complete the privacy, age rating, and app review information.
4. Add screenshots and promotional text.
5. Submit for review.

### 6. App Review tips
- Make sure the app is useful and stable.
- Avoid misleading claims or unclear functionality.
- Keep the experience simple and focused.
- Be ready to answer review questions if Apple requests more details.

## Next steps
- Add real web search integration for live recommendations.
- Add swipe gestures instead of buttons.
- Add persistence for saved decisions.
- Add Apple Sign In and iCloud sync.
- Add analytics and A/B testing.
