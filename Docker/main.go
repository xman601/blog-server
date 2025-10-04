package main

import (
	"fmt"
	"net/http"
	"html/template"
	"io/ioutil"
	"path/filepath"
	"log"
	"strings"
	"strconv"
	"sort"
	"time"
	"flag"

	"github.com/gomarkdown/markdown"
	"github.com/gomarkdown/markdown/html"
	"github.com/gomarkdown/markdown/parser"
)

var (
	templates *template.Template
	docsPath string
)

func main() {
	flag.StringVar(&docsPath, "docs", "docs", "path to directory containing markdown (.md) files")
	flag.Parse()

	templates, err := template.ParseGlob("templates/*.html")
	if err != nil {
		log.Fatalf("Error loading templates: %v", err)
	}

	fileserver := http.FileServer(http.Dir("public"))

	http.Handle("/", fileserver)
	http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
	})
	http.HandleFunc("/api/posts", func(w http.ResponseWriter, r *http.Request) {
		posts := loadPosts()

		if len(posts) == 0 {
			fmt.Fprint(w, "<p>No posts available yet.</p>")
			return
		}

		limit := len(posts)
		if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
			if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 {
				if parsedLimit < limit {
					limit = parsedLimit
				}
			}
		}

		var html strings.Builder
		for i := 0; i < limit; i++ {
			err := templates.ExecuteTemplate(&html, "post-card.html", posts[i])
			if err != nil {
				log.Printf("Error executing template: %v", err)
			}
		}

		w.Header().Set("Content-Type", "text/html")
		fmt.Fprint(w, html.String())
	})
	http.HandleFunc("/api/post/", func(w http.ResponseWriter, r *http.Request) {
		slug := strings.TrimPrefix(r.URL.Path, "/api/post/")

		posts := loadPosts()

		var post *Post
		for i := range posts {
			if posts[i].Slug == slug {
				post = &posts[i]
				break
			}
		}

		if post == nil {
			http.NotFound(w, r)
			return
		}

		w.Header().Set("Content-Type", "text/html")
		err := templates.ExecuteTemplate(w, "post.html", post)
		if err != nil {
			log.Printf("Error executing template: %v", err)
		}
	})

	http.ListenAndServe(":8000", nil)
}

type Post struct {
	Slug string
	Title string
	Content template.HTML
	Date time.Time
	Preview string
}

func loadPosts() []Post {
	var posts []Post

	files, err := ioutil.ReadDir(docsPath)
	if err != nil {
		log.Printf("Error reading docs directory: %v", err)
		return posts
	}

	for _, file := range files {
		if filepath.Ext(file.Name()) == ".md" {
			content, err := ioutil.ReadFile(filepath.Join("docs", file.Name()))
			if err != nil {
				log.Printf("Error reading file %s: %v", file.Name(), err)
				continue
			}

			htmlContent := mdToHtml(content)
			slug := strings.TrimSuffix(file.Name(), ".md")

			lines := strings.Split(string(content), "\n")
			title := strings.TrimPrefix(lines[0], "# ")
			preview := ""
			if len(lines) > 2 {
				preview = strings.TrimSpace(lines[2])
				if len(preview) > 150 {
					preview = preview[:150] + "..."
				}
			}

			post := Post{
				Slug: slug,
				Title: title,
				Content: template.HTML(htmlContent),
				Date: file.ModTime(),
				Preview: preview,
			}
			posts = append(posts, post)
		}
	}

	sort.Slice(posts, func(i, j int) bool {
		return posts[i].Date.After(posts[j].Date)
	})

	return posts
}

func mdToHtml(md []byte) []byte {
	extensions := parser.CommonExtensions | parser.AutoHeadingIDs
	p := parser.NewWithExtensions(extensions)
	doc := p.Parse(md)

	htmlFlags := html.CommonFlags | html.HrefTargetBlank
	opts := html.RendererOptions{Flags: htmlFlags}
	renderer := html.NewRenderer(opts)

	return markdown.Render(doc, renderer)
}
