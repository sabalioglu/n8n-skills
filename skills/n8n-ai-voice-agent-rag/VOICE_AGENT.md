# Voice Agent Integration Guide

Complete guide for integrating AI voice capabilities with n8n workflows, connecting voice platforms to the RAG-powered AI agent.

---

## Voice Platform Overview

### How Voice Agents Work

```
Caller → Voice Platform (STT) → Transcript → n8n Webhook
  → AI Agent (RAG retrieval) → Response Text
  → n8n HTTP Response → Voice Platform (TTS) → Caller hears speech
```

**STT** = Speech-to-Text (caller's voice → text)
**TTS** = Text-to-Speech (AI response → audio)

The voice platform handles the audio layer. n8n handles the intelligence layer.

### Platform Comparison

| Platform | STT | TTS | Ease of Setup | Latency | Cost |
|----------|-----|-----|---------------|---------|------|
| **Vapi.ai** | Built-in | Built-in | Easiest | Low | Per-minute |
| **Bland.ai** | Built-in | Built-in | Easy | Low | Per-minute |
| **Retell.ai** | Built-in | Built-in | Easy | Low | Per-minute |
| **Twilio** | Add-on (Gather) | Add-on (Say/Play) | Medium | Medium | Per-minute + STT/TTS |
| **Vonage** | WebSocket | External (ElevenLabs) | Complex | Variable | Per-minute + extras |

**Recommendation**: Start with **Vapi.ai** or **Bland.ai** for the fastest path to a working voice agent. They handle all audio complexity and let you focus on the AI logic in n8n.

---

## Vapi.ai Integration (Recommended)

### How Vapi Works with n8n

```
1. Vapi receives phone call
2. Vapi transcribes speech (STT)
3. Vapi sends transcript to YOUR n8n webhook (server URL)
4. n8n AI Agent processes with RAG
5. n8n returns response text
6. Vapi converts to speech (TTS) and speaks to caller
```

### Vapi Setup

**1. Create Vapi Assistant** (in Vapi dashboard):
```json
{
  "name": "Prospect Research Agent",
  "model": {
    "provider": "custom-llm",
    "url": "https://your-n8n-instance.com/webhook/vapi-agent",
    "temperature": 0.7
  },
  "voice": {
    "provider": "11labs",
    "voiceId": "rachel"
  },
  "firstMessage": "Hi! I've been researching your company. How can I help you today?",
  "serverUrl": "https://your-n8n-instance.com/webhook/vapi-server"
}
```

**2. n8n Webhook for Vapi Server Messages**:
```javascript
// Webhook node configuration
{
  path: "vapi-server",
  httpMethod: "POST",
  responseMode: "lastNode"
}
```

**3. Handle Vapi Message Types**:
```javascript
// Code node - route Vapi messages
const message = $input.first().json.body.message;

switch (message.type) {
  case 'function-call':
    // Vapi is requesting your n8n function to execute
    return [{
      json: {
        type: 'function-call',
        functionName: message.functionCall.name,
        parameters: message.functionCall.parameters,
        callId: $input.first().json.body.message.call?.id
      }
    }];

  case 'assistant-request':
    // Vapi wants your custom LLM to respond
    return [{
      json: {
        type: 'assistant-request',
        messages: message.messages,
        callId: message.call?.id
      }
    }];

  case 'status-update':
    // Call status changed (started, ended, etc.)
    return [{
      json: {
        type: 'status-update',
        status: message.status,
        callId: message.call?.id
      }
    }];

  default:
    return [{ json: { type: 'unknown', raw: message } }];
}
```

**4. Response Format for Vapi**:
```javascript
// For function-call responses:
{
  results: [{
    toolCallId: callId,
    result: "The prospect's main product is..."
  }]
}

// For assistant-request (custom LLM):
{
  id: "chatcmpl-custom",
  object: "chat.completion",
  choices: [{
    message: {
      role: "assistant",
      content: agentResponse
    }
  }]
}
```

### Vapi + n8n Complete Flow

```
Webhook (vapi-server)
  → Code (route message type)
  → Switch (by message type)
    ├─ [function-call] → AI Agent (RAG) → Code (format Vapi response)
    ├─ [assistant-request] → AI Agent (RAG) → Code (format as chat completion)
    └─ [status-update] → Code (log call events)
  → Respond to Webhook
```

---

## Bland.ai Integration

### How Bland Works with n8n

Bland.ai provides a simpler webhook model:

```
1. Bland receives call (inbound) or initiates call (outbound)
2. Bland transcribes and sends each turn to your webhook
3. Your webhook responds with text
4. Bland speaks the text to the caller
```

### Bland Setup

**1. Create Bland Agent via API**:
```javascript
// HTTP Request node to create Bland agent
{
  method: "POST",
  url: "https://api.bland.ai/v1/calls",
  body: {
    phone_number: "+1234567890",
    task: "Research prospect and have a sales conversation",
    webhook: "https://your-n8n-instance.com/webhook/bland-agent",
    model: "enhanced",
    voice: "maya",
    first_sentence: "Hi, thanks for taking my call!",
    max_duration: 300,
    // Pass prospect_id as metadata
    metadata: {
      prospect_id: "abc123"
    }
  }
}
```

**2. n8n Webhook for Bland**:
```javascript
// Webhook node
{
  path: "bland-agent",
  httpMethod: "POST",
  responseMode: "lastNode"
}
```

**3. Process Bland Webhook**:
```javascript
// Code node - extract Bland call data
const body = $input.first().json.body;

return [{
  json: {
    transcript: body.transcript || body.text,
    call_id: body.call_id,
    prospect_id: body.metadata?.prospect_id,
    call_status: body.status
  }
}];
```

**4. Response to Bland**:
```javascript
// Code node - format response for Bland
const agentResponse = $('AI Agent').first().json.output;

return [{
  json: {
    response: agentResponse
    // Bland will speak this text
  }
}];
```

### Bland Outbound Calling Workflow

```
1. Schedule/Manual Trigger
2. Database (get prospects to call)
3. Split In Batches
4. HTTP Request (POST to Bland API - initiate call)
   - Include prospect_id in metadata
5. Wait (between calls)
6. Log results
```

---

## Retell.ai Integration

### Retell Webhook Setup

```javascript
// Webhook node
{
  path: "retell-agent",
  httpMethod: "POST",
  responseMode: "lastNode"
}

// Retell sends:
{
  "call_id": "xxx",
  "transcript": [
    { "role": "agent", "content": "Hello!" },
    { "role": "user", "content": "Tell me about your products" }
  ],
  "response_id": 1
}

// n8n responds with:
{
  "response_id": 1,
  "content": "Based on your website, your main product is...",
  "content_complete": true
}
```

---

## Twilio + Custom TTS Integration

### For Full Control

Use Twilio for call handling with external STT/TTS:

### Inbound Call Flow

```
1. Twilio receives call → sends webhook to n8n
2. n8n responds with TwiML (Gather + Say)
3. Caller speaks → Twilio transcribes (Gather)
4. Twilio sends transcription to n8n
5. n8n AI Agent processes → returns TwiML with response
6. Loop continues until call ends
```

### n8n Webhook for Twilio
```javascript
// Webhook node
{
  path: "twilio-voice",
  httpMethod: "POST",
  responseMode: "responseNode"
}
```

### Initial Call Greeting (TwiML)
```javascript
// Code node - generate initial TwiML
const twiml = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="Polly.Joanna">
    Hi! I've done some research on your company. What would you like to discuss?
  </Say>
  <Gather
    input="speech"
    action="https://your-n8n-instance.com/webhook/twilio-gather"
    speechTimeout="auto"
    language="en-US">
  </Gather>
</Response>`;

return [{ json: { twiml } }];
```

### Handle Caller Speech
```javascript
// Second webhook - receives Gather results
// Webhook path: "twilio-gather"

const speechResult = $input.first().json.body.SpeechResult;
const callSid = $input.first().json.body.CallSid;

// Pass to AI Agent for processing
return [{
  json: {
    transcript: speechResult,
    call_id: callSid,
    prospect_id: $input.first().json.body.prospect_id // from custom parameter
  }
}];
```

### Response TwiML with AI Answer
```javascript
// Code node - after AI Agent processes
const agentResponse = $('AI Agent').first().json.output;

const twiml = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say voice="Polly.Joanna">${agentResponse}</Say>
  <Gather
    input="speech"
    action="https://your-n8n-instance.com/webhook/twilio-gather"
    speechTimeout="auto"
    language="en-US">
  </Gather>
</Response>`;

return [{ json: { twiml } }];
```

### Optional: ElevenLabs TTS (Higher Quality Voice)
```javascript
// HTTP Request - generate speech with ElevenLabs
{
  method: "POST",
  url: "https://api.elevenlabs.io/v1/text-to-speech/{{ $json.voice_id }}/stream",
  body: {
    text: agentResponse,
    model_id: "eleven_turbo_v2",
    voice_settings: {
      stability: 0.5,
      similarity_boost: 0.75
    }
  },
  // Returns audio binary
  // Host the audio and use <Play> in TwiML instead of <Say>
}
```

---

## AI Agent Configuration for Voice

### System Prompt (Optimized for Voice)

```
You are a knowledgeable sales assistant on a live phone call. You have researched the prospect's company thoroughly using their website.

CRITICAL VOICE RULES:
1. Keep ALL responses to 2-3 sentences maximum
2. Be conversational - use natural speech patterns
3. Never use bullet points, lists, or formatting (this is spoken)
4. Don't say "based on my research" - just reference the info naturally
5. Ask one follow-up question per response to keep the conversation going
6. If you don't know something, say "I don't have that specific detail, but..."

CONVERSATION FLOW:
1. Acknowledge what the caller said
2. Provide relevant information from their website
3. Connect it to how you can help
4. Ask a discovery question

TONE: Professional but warm, not robotic. Sound like a well-prepared human.
```

### Voice-Optimized Response Formatting

```javascript
// Code node - post-process AI response for voice
const response = $('AI Agent').first().json.output;

// Clean up for speech
let voiceResponse = response
  // Remove any markdown formatting
  .replace(/\*\*([^*]+)\*\*/g, '$1')
  .replace(/\*([^*]+)\*/g, '$1')
  .replace(/#+\s/g, '')
  .replace(/[-•]\s/g, '')
  // Remove URLs (don't speak URLs)
  .replace(/https?:\/\/[^\s]+/g, '')
  // Remove parenthetical references
  .replace(/\([^)]*\)/g, '')
  // Normalize whitespace
  .replace(/\s+/g, ' ')
  .trim();

// Enforce length limit for natural speech (~30 seconds of speech)
const sentences = voiceResponse.match(/[^.!?]+[.!?]+/g) || [voiceResponse];
if (sentences.length > 4) {
  voiceResponse = sentences.slice(0, 3).join(' ').trim();
}

return [{ json: { response: voiceResponse } }];
```

---

## Conversation Memory for Voice Calls

### Per-Call Memory

Each phone call should have its own conversation memory:

```javascript
// Window Buffer Memory configuration
{
  sessionKey: "={{ $json.body.call_id }}",
  contextWindowLength: 20  // Last 20 exchanges
}
```

### Memory Cleanup After Call

```
Call Status = "ended"
  → Code (extract call summary)
  → Database (store call log)
  → Memory cleanup (if using external store)
```

### Call Logging
```javascript
// Code node - log completed call
const callData = $input.first().json;

return [{
  json: {
    call_id: callData.call_id,
    prospect_id: callData.prospect_id,
    duration: callData.duration,
    summary: callData.summary || 'Call completed',
    timestamp: new Date().toISOString(),
    // Store for CRM update or analytics
  }
}];
```

---

## Outbound Calling Workflow

### Automated Prospect Outreach

```
1. Schedule Trigger (or Manual)
2. Database/CRM (get prospects with "knowledge: ready" status)
3. Code (prepare call list)
4. Split In Batches (one call at a time)
5. HTTP Request (initiate call via Bland/Vapi API)
6. Wait (3-5 minutes between calls)
7. Webhook (receive call results)
8. Database (update prospect status)
```

### Initiating Outbound Call (Bland.ai)
```javascript
{
  method: "POST",
  url: "https://api.bland.ai/v1/calls",
  headers: {
    Authorization: "{{ $env.BLAND_API_KEY }}"
  },
  body: {
    phone_number: "={{ $json.phone }}",
    task: `You are calling from [Company]. You've researched ${$json.company_name} and want to discuss how your solution can help them. Be professional and conversational.`,
    webhook: "https://your-n8n.com/webhook/bland-agent",
    model: "enhanced",
    voice: "maya",
    first_sentence: `Hi, is this someone from ${$json.company_name}? This is [Name] from [Company].`,
    max_duration: 300,
    metadata: {
      prospect_id: $json.prospect_id
    }
  }
}
```

### Initiating Outbound Call (Vapi.ai)
```javascript
{
  method: "POST",
  url: "https://api.vapi.ai/call/phone",
  headers: {
    Authorization: "Bearer {{ $env.VAPI_API_KEY }}"
  },
  body: {
    phoneNumberId: "your-vapi-phone-number-id",
    customer: {
      number: "={{ $json.phone }}"
    },
    assistantId: "your-vapi-assistant-id",
    // Or inline assistant config with serverUrl pointing to n8n
  }
}
```

---

## Error Handling for Voice

### Graceful Fallbacks

```javascript
// Code node - handle errors gracefully for voice
const aiOutput = $('AI Agent').first().json;

let response;
if (aiOutput.error || !aiOutput.output) {
  // Fallback response when AI fails
  response = "I apologize, I'm having a brief technical issue. Could you repeat that? I want to make sure I give you accurate information.";
} else {
  response = aiOutput.output;
}

return [{ json: { response } }];
```

### Timeout Handling
```javascript
// If AI takes too long, provide interim response
// Configure timeout on AI Agent node: 10 seconds max

// Fallback:
"That's a great question. Let me think about that for a moment..."
```

### Call Transfer
```javascript
// If the AI can't handle the request, transfer to human
// Twilio TwiML:
const twiml = `<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Say>Let me connect you with a specialist who can help with that.</Say>
  <Dial>+1234567890</Dial>
</Response>`;
```

---

## Testing Voice Agents

### 1. Test Without Voice First

Use the n8n webhook directly to test the AI + RAG pipeline:

```bash
# Test ingestion
curl -X POST https://your-n8n.com/webhook/ingest-prospect \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example-prospect.com", "prospect_id": "test1"}'

# Test voice agent (simulate voice input)
curl -X POST https://your-n8n.com/webhook/vapi-server \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "type": "function-call",
      "functionCall": {
        "name": "search_prospect_knowledge",
        "parameters": {"query": "What products do they offer?"}
      }
    }
  }'
```

### 2. Test Voice Platform Locally

Most voice platforms support test calls:
- **Vapi**: Use dashboard "Test Call" button
- **Bland**: Send API call with your own phone number
- **Twilio**: Use TwiML Bin for testing

### 3. Test Conversation Quality

Questions to verify:
- "Tell me about [prospect] company" → Should reference website content
- "What products do they offer?" → Should list actual products
- "How does this relate to us?" → Should connect prospect info to your offering
- Random question → Should gracefully handle with "I don't have that specific info"

---

## Latency Optimization

Voice agents are latency-sensitive. Target < 2 seconds total response time.

| Component | Target Latency | Optimization |
|-----------|---------------|-------------|
| Voice platform STT | 200-500ms | Platform handles this |
| n8n webhook receive | 50-100ms | Keep n8n instance warm |
| Vector store retrieval | 100-300ms | Use managed service, proper indexes |
| LLM generation | 500-1500ms | Use fast models (GPT-4o-mini, Haiku) |
| Voice platform TTS | 200-500ms | Use streaming TTS |
| **Total** | **~1-3 seconds** | |

### Tips
- Use **GPT-4o-mini** or **Claude 3.5 Haiku** instead of full GPT-4/Opus
- Set **topK: 3** for vector retrieval (less data to process)
- Keep system prompts **concise** (fewer tokens = faster)
- Use **streaming** where platform supports it
- Place n8n instance in **same region** as voice platform

---

## Summary

**Key Points**:
1. **Voice platform handles audio** (STT/TTS) - n8n handles AI intelligence
2. **Vapi.ai or Bland.ai** recommended for easiest setup
3. **2-3 sentence responses** for natural voice conversation
4. **Per-call memory** using call_id as session key
5. **Latency matters** - use fast models and limit retrieval
6. **Test without voice first** - verify AI + RAG works via direct webhook

**Architecture**:
```
Phone Call → Voice Platform (STT) → n8n Webhook → AI Agent (RAG) → n8n Response → Voice Platform (TTS) → Speech
```

**Related Files**:
- [SKILL.md](SKILL.md) - Overall architecture
- [RAG_SETUP.md](RAG_SETUP.md) - Vector store configuration
- [WEB_SCRAPING.md](WEB_SCRAPING.md) - Content extraction
