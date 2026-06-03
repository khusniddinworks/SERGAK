import sys
import os

# Add the bot directory to path so it can import security
bot_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "sergak web bot", "sergak_bot"))
sys.path.insert(0, bot_dir)

# Change working directory to the bot directory so file paths (like bot.log, .env) are correct
os.chdir(bot_dir)

# Now run the bot
if __name__ == "__main__":
    from bot import main
    main()
