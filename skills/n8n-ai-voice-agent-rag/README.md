# n8n AI Voice Agent with RAG

Expert guidance for building AI voice agents that scrape prospect websites, store knowledge in vector databases, and use it in real-time voice conversations.

---

## Purpose

Teaches how to build a complete AI voice agent pipeline in n8n:
1. Scrape and extract content from prospect websites
2. Store knowledge in a vector database (RAG)
3. Retrieve relevant information during live voice calls
4. Integrate with voice platforms (Vapi, Bland.ai, Twilio)

---

## Activates On

**Trigger keywords**:
- "voice agent"
- "AI voice"
- "phone agent"
- "voice bot"
- "RAG pipeline"
- "vector store retrieval"
- "scrape website for AI"
- "prospect research automation"
- "knowledge base from website"
- "voice conversation AI"
- "Vapi integration"
- "Bland.ai workflow"
- "Twilio voice AI"
- "website to vector store"
- "embedding pipeline"

**Common scenarios**:
- Building an AI agent that makes/receives phone calls
- Scraping prospect websites to prepare for sales calls
- Setting up RAG with vector stores in n8n
- Integrating Vapi, Bland.ai, or Twilio with n8n
- Creating a knowledge base from web content
- Building outbound calling automation

---

## What You'll Learn

### Architecture
- 3-phase system: Ingest → Store → Voice Retrieve
- Web scraping pipeline design
- RAG storage with vector databases
- Voice platform webhook integration

### Web Scraping (Phase 1)
- Single-page and multi-page scraping strategies
- HTML content extraction with CSS selectors
- Content cleaning and quality checks
- Link discovery and priority page selection
- Rate limiting and error handling

### RAG Setup (Phase 2)
- Text splitting strategies and chunk sizes
- Embedding model selection and configuration
- Vector store comparison (Supabase, Pinecone, Qdrant)
- Prospect data isolation (namespace vs metadata filtering)
- Insert mode vs retrieve mode configuration

### Voice Agent (Phase 3)
- Voice platform integration (Vapi, Bland.ai, Retell, Twilio)
- AI Agent configuration with vector store tool
- Voice-optimized system prompts
- Response formatting for natural speech
- Per-call conversation memory
- Outbound calling automation
- Latency optimization

---

## File Structure

```
n8n-ai-voice-agent-rag/
├── SKILL.md (~500 lines)
│   Complete architecture overview
│   - 3-phase system design
│   - Phase 1: Knowledge ingestion workflow
│   - Phase 2: Voice agent workflow
│   - Phase 3: Prospect management
│   - Quick start guide
│   - Node discovery reference
│   - Common gotchas
│   - Security considerations
│   - Performance optimization
│
├── WEB_SCRAPING.md (~400 lines)
│   Website content extraction
│   - Single-page vs multi-page strategies
│   - Priority pages to scrape
│   - Link discovery code
│   - HTML extraction configuration
│   - Content cleaning patterns
│   - JavaScript-rendered page handling
│   - Quality checks and deduplication
│   - Sitemap-based alternative
│   - Error handling
│
├── RAG_SETUP.md (~400 lines)
│   Vector store and embedding setup
│   - RAG architecture in n8n
│   - Text splitting strategies
│   - Embedding model comparison
│   - Vector store comparison (Supabase, Pinecone, Qdrant)
│   - Supabase pgvector setup (SQL included)
│   - Prospect data isolation strategies
│   - Cleanup and re-ingestion
│   - Monitoring and debugging
│
├── VOICE_AGENT.md (~500 lines)
│   Voice platform integration
│   - Platform comparison (Vapi, Bland, Retell, Twilio)
│   - Vapi.ai integration (recommended)
│   - Bland.ai integration
│   - Retell.ai integration
│   - Twilio + ElevenLabs integration
│   - Voice-optimized AI prompts
│   - Response formatting for speech
│   - Conversation memory
│   - Outbound calling workflows
│   - Error handling for voice
│   - Testing strategies
│   - Latency optimization
│
└── README.md (this file)
    Skill metadata and overview
```

**Total**: ~1,800 lines across 5 files

---

## Coverage

### Web Scraping
- HTTP Request + HTML Extract node configuration
- Multi-page crawling with link discovery
- Content cleaning (boilerplate removal, deduplication)
- Rate limiting and error handling
- Sitemap-based alternative approach

### RAG Pipeline
- Token-based text splitting (400 tokens, 50 overlap)
- OpenAI embeddings (text-embedding-3-small recommended)
- Three vector store options with full setup guides
- Prospect data isolation patterns
- Same-model consistency rule

### Voice Integration
- Four voice platform integrations with code examples
- Vapi.ai recommended path (easiest setup)
- Bland.ai for outbound calling
- Twilio for full control
- Voice-specific AI prompt engineering

### Production Concerns
- Security (input validation, data isolation, webhook authentication)
- Performance (latency optimization, model selection, caching)
- Error handling (graceful fallbacks, call transfer)
- Monitoring (retrieval quality, call logging)

---

## Integration with Other Skills

### n8n Workflow Patterns
- AI Agent Workflow pattern is the foundation for the voice agent
- Webhook Processing pattern for voice platform callbacks

### n8n MCP Tools Expert
- Find AI/vector store nodes: `search_nodes({query: "vector store"})`
- Get essentials: `get_node_essentials({nodeType: "@n8n/n8n-nodes-langchain.vectorStorePinecone"})`

### n8n Node Configuration
- AI connection types (ai_tool, ai_memory, ai_languageModel, ai_embedding, ai_vectorStore)
- Property dependencies for vector store modes

### n8n Expression Syntax
- Webhook data access: `{{ $json.body.url }}`
- Node references: `{{ $('Webhook').first().json.body.prospect_id }}`

### n8n Code JavaScript
- Content cleaning code patterns
- Response formatting for voice
- Link discovery and extraction

### n8n Validation Expert
- Validate AI workflow configurations
- Check vector store connections

---

## Quick Start Path

1. **Set up vector store** (Supabase recommended - see RAG_SETUP.md)
2. **Build ingestion workflow** (5 nodes - see SKILL.md Phase 1)
3. **Build voice agent workflow** (4 nodes - see SKILL.md Phase 2)
4. **Connect voice platform** (Vapi recommended - see VOICE_AGENT.md)
5. **Test** with a sample prospect website

---

## Evaluations

**5 test scenarios** covering:
1. Web scraping and content extraction pipeline
2. RAG vector store setup (insert + retrieve)
3. Voice agent with prospect knowledge retrieval
4. Prospect data isolation across multiple prospects
5. End-to-end voice agent with Vapi integration

Each evaluation tests skill activation, correct architecture guidance, and reference to appropriate documentation files.

---

## Version History

- **v1.0** (2026-02-01): Initial implementation
  - SKILL.md with 3-phase architecture
  - WEB_SCRAPING.md with multi-page scraping strategies
  - RAG_SETUP.md with vector store comparison and setup
  - VOICE_AGENT.md with 4 platform integrations
  - 5 evaluation scenarios

---

## Author

Conceived by Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

Part of the n8n-skills collection.
