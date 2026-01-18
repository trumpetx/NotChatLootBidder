This addon allows the pop-up of loot frames which interact with the [ChatLootBidder](https://github.com/trumpetx/ChatLootBidder) Master Looter addon, and also supports [RollFor](https://github.com/obszczymucha/roll-for-vanilla)(Vanilla) and [RollFor](https://github.com/sica42/RollFor)(Turtle) for automated rolling.

![image](https://github.com/user-attachments/assets/c1b1f63a-045a-42a9-a511-3d23ff80fdb8)

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
  /bid rollfor  - Enable or disable RollFor support
  /bid info  - Show information about the add-on
  /bid help  - Show this message again
```

Chagelog:

1.9.2
* Canceling the pop-up window win bidding on an item has been canceled

1.9.1
* Suppressing pop-ups when RollFor SR announcement does not include the player; only showing MS option in this situation
* Displaying a message when there is custom rolling logic (manual rolling required)

1.9.0
* Added RollFor support - automatically shows popup frames when master looter announces rolls via RollFor
* RollFor frames support MS/OS/T-mog buttons that automatically roll with the correct thresholds
* Use `/bid rollfor` to enable or disable RollFor support (enabled by default)

1.8.1-2
* Fixing the error `NotChatLootBidder.lua: attempt to index field ``Point' (a nil value)`

1.8.0
* Adding a "Spec" dropdown in the bid menu which will prepend the spec with the other "params" (like ALT and NR)

1.7.2
* Adding a checkbox (similar to the ALT checkbox) for "No-Reply" which will eventually be consumed by [ChatLootBidder](https://github.com/trumpetx/ChatLootBidder)
* Making the bid box a few pixels bigger to accommodate the new checkbox

1.7.1
* Display 1H Axes + Rogues when on Turtle when using `/bid autoignore`
* Refactoring code to allow NotChatLootBidder to operate on 3.3.5a clients (.toc update notwithstanding)

1.7.0
* Adding a checkbox to track whether a specific character is an "ALT".  This information will be eventually consumed by [ChatLootBidder](https://github.com/trumpetx/ChatLootBidder)

1.6.0
* Adding a default message unique to your current character `/bid message Prot` would pre-populate the "note" as `Prot` for the character you're on right now
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
