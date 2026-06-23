# Welcome to your LLM Wiki

This vault is maintained by an AI agent following the [llm-wiki-kit](https://github.com/) skills. Knowledge is **compiled** here, not re-derived on every question.

## Start here

- **Browse:** open [[_system/index.md]] for the full table of contents.
- **Recent context:** [[_system/hot.md]] is a ~500-word snapshot of what changed lately.
- **Add knowledge:** drop a source in `raw/` or just tell your agent *"ingest this"* → it runs `wiki-ingest`.
- **Ask:** *"what do I know about X?"* → it runs `wiki-query` and answers with `[[links]]` to source pages.
- **Maintain:** *"audit my wiki"* → it runs `wiki-lint` for orphans, broken links, and contradictions.

## How it works

| You do | The agent does |
|--------|----------------|
| Choose sources | Summarize & distill |
| Ask questions | Cross-reference & link |
| Judge what matters | File, tag, keep consistent |

Every page lives in `notes/`, carries a `category` in its frontmatter, and links to related pages. The agent keeps `_system/index.md` and `_system/hot.md` current automatically.
