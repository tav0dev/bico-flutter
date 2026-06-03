const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const schema = {
  type: "object",
  additionalProperties: false,
  properties: {
    caption: { type: "string" },
    hashtags: {
      type: "array",
      items: { type: "string" },
    },
    image_prompt: { type: "string" },
    visual_tips: {
      type: "array",
      items: { type: "string" },
    },
  },
  required: ["caption", "hashtags", "image_prompt", "visual_tips"],
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return json({ message: "Use POST." }, 405);
  }

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    return json({ message: "OPENAI_API_KEY nao configurada." }, 500);
  }

  try {
    const payload = await request.json();
    const action = String(payload.action ?? "generate_post");

    if (action === "generate_image") {
      return json(await generateImage(apiKey, payload));
    }

    return json(await generatePost(apiKey, payload));
  } catch (error) {
    return json({ message: errorMessage(error) }, 500);
  }
});

async function generatePost(apiKey: string, payload: Record<string, unknown>) {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("OPENAI_TEXT_MODEL") ?? "gpt-5-mini",
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text:
                "Voce e um estrategista de marketing para prestadores de servico no Brasil. Escreva em portugues brasileiro, simples, direto e vendavel. Nao invente promessas, resultados ou dados. Responda apenas JSON valido.",
            },
          ],
        },
        {
          role: "user",
          content: [{ type: "input_text", text: promptFromPayload(payload) }],
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "marketing_post",
          strict: true,
          schema,
        },
      },
    }),
  });

  const body = await response.text();
  if (!response.ok) throw new Error(openAiError(body, response.status));

  const decoded = JSON.parse(body);
  return JSON.parse(extractOutputText(decoded));
}

async function generateImage(apiKey: string, payload: Record<string, unknown>) {
  const prompt = String(payload.prompt ?? "").trim();
  if (!prompt) throw new Error("Prompt vazio.");

  const response = await fetch("https://api.openai.com/v1/images/generations", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("OPENAI_IMAGE_MODEL") ?? "gpt-image-1",
      prompt,
      size: "1024x1024",
    }),
  });

  const body = await response.text();
  if (!response.ok) throw new Error(openAiError(body, response.status));

  const decoded = JSON.parse(body);
  const firstImage = decoded.data?.[0]?.b64_json;
  if (!firstImage) throw new Error("Resposta de imagem sem dados.");
  return { b64_json: firstImage };
}

function promptFromPayload(payload: Record<string, unknown>) {
  return `
Crie uma divulgacao para um prestador de servicos.

Dados:
${JSON.stringify(payload, null, 2)}

Retorne:
- caption: legenda pronta, natural, com chamada para agendar.
- hashtags: 5 a 8 hashtags curtas, sem acentos se possivel.
- image_prompt: prompt detalhado para gerar uma imagem/post quadrado profissional.
- visual_tips: 3 dicas curtas para melhorar a imagem atual.
`;
}

function extractOutputText(body: Record<string, unknown>) {
  const direct = body.output_text;
  if (typeof direct === "string" && direct.trim()) return direct;

  const output = body.output;
  if (Array.isArray(output)) {
    for (const item of output) {
      const content = item?.content;
      if (!Array.isArray(content)) continue;
      for (const part of content) {
        if (typeof part?.text === "string" && part.text.trim()) {
          return part.text;
        }
      }
    }
  }

  throw new Error("A IA respondeu sem texto utilizavel.");
}

function openAiError(body: string, status: number) {
  try {
    const decoded = JSON.parse(body);
    return decoded.error?.message ?? decoded.message ?? `Erro ${status}.`;
  } catch {
    return `Erro ${status}.`;
  }
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
