@echo off
echo Pushing to git repository...
git add -A
git commit -m "Update files"
git push -u origin main
echo Push completed!
pause