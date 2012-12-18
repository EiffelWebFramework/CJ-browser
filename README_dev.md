Requirement:
compile with EiffelStudio 7.1

-- Administration purpose
git remote add -f ewf https://github.com/EiffelWebFramework/EWF.git
git merge -s ours --no-commit ewf/master
git read-tree --prefix=lib/EWF -u ewf/master
git commit -m "Added subtree merged in lib/EWF"

git remote add -f cj https://github.com/jocelyn/CJ.git
git merge -s ours --no-commit cj/master
git read-tree --prefix=lib/CJ -u cj/master
git commit -m "Added subtree merged in lib/cj"


-- update

git pull -X subtree=lib/EWF ewf master
git pull -X subtree=lib/CJ cj master
