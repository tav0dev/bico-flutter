# bico-ai

Edge Function que protege a chave da OpenAI e atende a tela `Divulgar` do app.

## Configuracao de producao

1. Autentique o Supabase CLI:

```powershell
npx.cmd supabase login
```

2. Grave os secrets do projeto:

```powershell
npx.cmd supabase secrets set OPENAI_API_KEY="SUA_CHAVE_AQUI" --project-ref wzychmshebmznjfducug
npx.cmd supabase secrets set OPENAI_TEXT_MODEL="gpt-5-mini" OPENAI_IMAGE_MODEL="gpt-image-1" --project-ref wzychmshebmznjfducug
```

3. Publique a funcao:

```powershell
npx.cmd supabase functions deploy bico-ai --project-ref wzychmshebmznjfducug
```

4. Compile o app apontando para a funcao:

```powershell
flutter build apk --dart-define=BICO_AI_ENDPOINT=https://wzychmshebmznjfducug.supabase.co/functions/v1/bico-ai
```

