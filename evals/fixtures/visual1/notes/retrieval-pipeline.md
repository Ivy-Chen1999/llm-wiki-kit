---
title: Retrieval pipeline
category: concept
tags: [rag]
summary: The ordered stages of a RAG retrieval pipeline.
created: 2026-07-01
updated: 2026-07-01
---
# Retrieval pipeline
VISUAL_MARKER_KEEP
A retrieval pipeline runs in order:
1. Embed the query.
2. First-stage vector search for candidates.
3. Rerank the candidates with a stronger model.
4. Assemble context and generate the answer.
