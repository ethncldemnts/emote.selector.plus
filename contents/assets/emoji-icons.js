// Import the shared emoji list module
.import "emoji-list.js" as EmojiSource

// Dynamically populate iconEmojis from the shared emoji list
var iconEmojis = (function() {
    var allEmojis = [];
    var list = EmojiSource.emojiList;
    
    for (var category in list) {
        var categoryData = list[category];
        if (categoryData) {
            for (var i = 0; i < categoryData.length; i++) {
                allEmojis.push(categoryData[i].emoji);
            }
        }
    }
    
    return allEmojis;
})();
