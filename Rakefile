md_files = Rake::FileList.new("**/*.md") do |fl|
  fl.exclude("index.md")
  fl.exclude("README.md")
end

task :default => :html
task :html => md_files.ext(".html")

rule ".html" => ".md" do |t|
  sh "pandoc -s -S -c /homelab/design/style.css --toc #{t.source} -o #{t.name}"
end

gv_files = Rake::FileList.new("**/*.gv") do |fl|
end

task :default => :svg
task :svg => gv_files.ext(".svg")

rule ".svg" => ".gv" do |t|
  sh "dot -T svg #{t.source} -o #{t.name}"
end
