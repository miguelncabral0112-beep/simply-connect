import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
const cors={ "Access-Control-Allow-Origin":Deno.env.get("APP_ORIGIN")??"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS","Content-Type":"application/json" };
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:cors});
Deno.serve(async(req)=>{
 if(req.method==="OPTIONS")return new Response("ok",{headers:cors});
 if(req.method!=="POST")return json({error:"Método não permitido."},405);
 const url=Deno.env.get("SUPABASE_URL"),anon=Deno.env.get("SUPABASE_ANON_KEY"),google=Deno.env.get("GOOGLE_PLACES_API_KEY");
 if(!url||!anon||!google)return json({error:"Integração pendente: configure os secrets SUPABASE_URL, SUPABASE_ANON_KEY e GOOGLE_PLACES_API_KEY."},503);
 const authorization=req.headers.get("Authorization");if(!authorization)return json({error:"Autenticação obrigatória."},401);
 const sb=createClient(url,anon,{global:{headers:{Authorization:authorization}}});const {data:{user},error:userError}=await sb.auth.getUser();
 if(userError||!user)return json({error:"Sessão inválida. Entre novamente."},401);
 let input:Record<string,unknown>;try{input=await req.json()}catch{return json({error:"Requisição inválida."},400)}
 const country=String(input.country??"").trim(),region=String(input.region??"").trim(),city=String(input.city??"").trim(),niche=String(input.niche??"").trim(),filter=String(input.websiteFilter??"all");
 if(!country||!city||!niche)return json({error:"País, cidade e nicho são obrigatórios."},400);
 if(city.length>100||region.length>100||niche.length>100)return json({error:"Um filtro excede o limite de caracteres."},400);
 try{
  const res=await fetch("https://places.googleapis.com/v1/places:searchText",{method:"POST",headers:{"Content-Type":"application/json","X-Goog-Api-Key":google,"X-Goog-FieldMask":"places.id,places.displayName,places.formattedAddress,places.nationalPhoneNumber,places.websiteUri,places.rating,places.userRatingCount,places.primaryTypeDisplayName,places.googleMapsUri,places.addressComponents"},body:JSON.stringify({textQuery:[niche,city,region,country].filter(Boolean).join(", "),pageSize:20,languageCode:"pt-BR"})});
  const data=await res.json();if(!res.ok)return json({error:"Google Places: "+String(data?.error?.message??"falha na busca.")},res.status===429?429:502);
  const results=(data.places??[]).map((p:any)=>{const c=p.addressComponents??[];const comp=(t:string)=>c.find((v:any)=>v.types?.includes(t))?.longText??null;return{place_id:String(p.id??""),name:String(p.displayName?.text??"Empresa sem nome"),country:comp("country")??country,region:(comp("administrative_area_level_1")??region)||null,city:comp("locality")??comp("administrative_area_level_2")??city,category:p.primaryTypeDisplayName?.text??niche,address:p.formattedAddress??null,phone:p.nationalPhoneNumber??null,website:p.websiteUri??null,rating:typeof p.rating==="number"?p.rating:null,rating_count:typeof p.userRatingCount==="number"?p.userRatingCount:null,maps_url:p.googleMapsUri??null}}).filter((p:any)=>p.place_id&&(filter==="missing"?!p.website:filter==="present"?Boolean(p.website):true));
  await sb.from("search_history").insert({user_id:user.id,filters:{country,region,city,niche,websiteFilter:filter},result_count:results.length});
  return json({results,count:results.length,source:"google_places",coverage_note:"A cobertura depende do Google Places e não representa todas as empresas da região."});
 }catch{return json({error:"Erro inesperado ao consultar o Google Places."},500)}
});
