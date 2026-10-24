// GARI grant search proxy — deploy as a Supabase Edge Function named "grant-search".
import { createClient } from "npm:@supabase/supabase-js@2";
const cors = {"Access-Control-Allow-Origin":"https://www.thegari.org","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
Deno.serve(async (req) => {
 if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
 const reply=(data,status=200)=>new Response(JSON.stringify(data),{status,headers:{...cors,"Content-Type":"application/json"}});
 if(req.method!=="POST")return reply({error:"Method not allowed"},405);
 try{
  const bearer=req.headers.get("Authorization");
  if(!bearer?.startsWith("Bearer "))return reply({error:"Sign in to GARI first"},401);
  const supabase=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_ANON_KEY")!,{global:{headers:{Authorization:bearer}}});
  const {data:{user},error:authError}=await supabase.auth.getUser();
  if(authError||!user)return reply({error:"Authentication required"},401);
  const {data:member}=await supabase.from("portal_members").select("role").eq("user_id",user.id).eq("active",true).maybeSingle();
  if(!member)return reply({error:"Not authorized"},403);
  const body=await req.json();
  const keyword=String(body?.keyword||"").trim().slice(0,100);
  if(!keyword)return reply({error:"Enter a search topic"},400);
  const upstream=await fetch("https://api.grants.gov/v1/api/search2",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({keyword,rows:25,oppStatuses:"forecasted|posted"}),signal:AbortSignal.timeout(12000)});
  if(!upstream.ok)return reply({error:"Grants.gov is temporarily unavailable",upstreamStatus:upstream.status},502);
  const result=await upstream.json();
  if(result.errorcode!==0)return reply({error:"Grants.gov search failed",detail:result.msg},502);
  return reply({hits:result.data?.oppHits??[],hitCount:result.data?.hitCount??0});
 }catch(e){return reply({error:"Unable to complete search",detail:String(e).slice(0,180)},502)}
});
