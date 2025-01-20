This addon allows the pop-up of loot frames which interact with the [ChatLootBidder](https://github.com/trumpetx/ChatLootBidder)  Master Looter addon.

![image](https://github.com/trumpetx/NotChatLootBidder/assets/115343/425413b5-f34d-415a-b8e6-77a32354ec41)

```
  /bid  - Open the placement frame
  /bid [item-link] [item-link2]  - Open test bid frames
  /bid scale [50-150]  - Set the UI scale percentage
  /bid autoignore  - Toggle 'auto-ignore' mode to ignore items your class cannot use
  /bid message  - Set a default message (per character)
  /bid ignore  - List all ignored items
  /bid ignore clear  - Clear the ignore list completely
  /bid ignore [item-link] [item-link2]  - Toggle 'Ignore' for loot windows of these item(s)
  /bid clear  - Clear all bid frames
  /bid info  - Show information about the add-on
  /bid help  - Show this message again
```

Chagelog:

1.7.0
* Adding a checkbox to track whether a specific character is an "ALT".  This information will be eventually consumed by [ChatLootBidder](https://github.com/trumpetx/ChatLootBidder)

1.6.0
* Adding a default message unique to your current character `/bid message alt; Prot` would pre-populate the "note" as `alt; Prot` for the character you're on right now
* Updated to latest ChatThrottleLib for Turtle (14.1)

1.5.0
* Improving 'autoignore' to filter out obviously inappropriate items from specific classes.  Use `/bid autoignore` to toggle this feature on and off

1.4.0
* Added support for MS/OS mode from ChatLootBidder

1.3.1
* Set the minimum bid (1 by default) if set by the Master Looter

1.3.0
* Auto-ignore items (configurable) by class usability `/bid autoignore`

1.2.0
* Set the frame sizes with the UI Scale and make it adjustable
* Ignore items on a list

1.1.0
* Close/disable frames when a Loot Session ends
