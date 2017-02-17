PWD=`pwd`
pandoc -o ~/www/index.html ~/www/index.md
pandoc -s -S -c /homelab/design/style.css --toc ~/www/design/overview.md -o ~/www/design/overview.html
pandoc -s -S -c /homelab/design/style.css --toc ~/www/design/design.md -o ~/www/design/design.html
pandoc -s -S -c /homelab/design/style.css --toc ~/www/design/implementation.md -o ~/www/design/implementation.html
cd ~/www
git add --all
git commit -m "Updated index.html"
git push origin master
cd $PWD
