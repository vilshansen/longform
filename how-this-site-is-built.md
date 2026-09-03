This site is built around a single core philosophy: **absolute structural simplicity with zero build overhead**.

There are no Node.js dependencies, complex static site generators (like Hugo or Gatsby), or build pipelines. Publishing a new post requires nothing more than committing a standard `.md` file to a Git repository.

## Architecture \& Data Flow

```
[ User Browser ]
│
├─► Request root (/) ──► Fetches index.html + index.json
│                           └── Renders Document Library (TOC)
│
└─► Request post (/?file=name.md) ──► Fetches index.json + clean .md path
├── Strips Front Matter
├── Parses Markdown via Marked.js
└── Injects Title \& Metadata
```

## Core Components

* **Flat-File JSON Registry (`index.json`)**: Acts as the central table of contents. It stores entry filenames, display titles, teaser blurbs, and publication dates.
* **Vanilla Client-Side Engine (`index.html`)**: A single HTML file handling both view routing and dynamic rendering using standard JavaScript `fetch()` calls.
* **Marked.js Engine**: Translates raw Markdown file text into clean HTML directly inside the user's browser runtime.
* **Jekyll Bypass (`.nojekyll`)**: Disables GitHub Pages' default static builder, ensuring `.md` files and JSON resources are served as raw static assets without HTTP 404 filtering.

## The Technical Lifecycle

### 1\. Library Index Rendering

When visiting the root URL without parameters:

1. `index.html` initiates a `fetch("index.json")` request.
2. The browser parses the array of post objects containing `file`, `title`, `blurb`, and `date`.
3. The script dynamically constructs a semantic `<ul>` library list styled with classic serif typography and warm cream hues.

### 2\. Post Hydration \& Routing

When a post link is selected (e.g., `?file=architecture-notes.md`):

1. The script extracts the `file` query parameter from the URL.
2. It fetches the metadata entry from `index.json` and the selected raw `.md` document.
3. Path cleaning normalizes any leading slashes or relative notation (`./`) to prevent subpath routing errors on hosted domains.
4. If an `<h1>` heading is absent from the Markdown body, the engine injects a top-level heading using the title defined in `index.json`.

## Key Benefits

* **Zero Build Steps**: No `npm install`, zero security vulnerabilities in `node\_modules`, and no compilation steps.
* **Portability**: The entire codebase consists of plain text files that run locally on any simple HTTP web server.
* **Pure Git Workflow**: Writing and publishing requires creating a `.md` file, adding its title, blurb, and publication date to `index.json`, and running `git push`.

