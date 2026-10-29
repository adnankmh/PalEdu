import { chromium } from 'playwright';
import { mkdir, writeFile } from 'node:fs/promises';

const browser=await chromium.launch({headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
const page=await browser.newPage({viewport:{width:430,height:930},deviceScaleFactor:2,locale:'ar-PS'});
const errors=[],captures=[];
page.on('pageerror',error=>errors.push(error.message));
const base=process.env.PALEDU_CAPTURE_URL||'http://127.0.0.1:8765/';
async function marker(text){
  for(let attempt=0;attempt<30;attempt++){
    for(const locator of [page.getByLabel(text,{exact:false}),page.getByText(text,{exact:false})]){
      if(await locator.first().isVisible().catch(()=>false))return;
    }
    await page.waitForTimeout(200);
  }
  throw Error('Expected screen marker missing: '+text);
}
async function click(label){
  const name=new RegExp(label);
  for(const locator of [page.getByRole('button',{name}),page.getByRole('tab',{name}),page.getByLabel(label,{exact:true}),page.getByText(label,{exact:true})]){
    try{await locator.first().click({timeout:2500});return}catch{}
  }
  throw Error('Cannot activate semantic control: '+label);
}
async function snap(name,text){
  await marker(text);
  await page.waitForTimeout(400);
  await page.screenshot({path:'captures/'+name+'.png'});
  captures.push({file:name+'.png',verifiedMarker:text});
}
try{
  await mkdir('captures',{recursive:true});
  await page.goto(base,{waitUntil:'domcontentloaded'});
  // Flutter draws with CanvasKit. Enable its semantics tree and operate real
  // labelled controls instead of guessing pixels and mislabelling screenshots.
  const semantics=page.locator('flt-semantics-placeholder');
  await semantics.waitFor({state:'attached',timeout:60000});
  await semantics.evaluate(element=>element.click());
  await snap('01-welcome','اختر طريقة الدخول');
  await click('معاينة تعليمية دون حساب');
  await snap('02-learner-setup','مستقبلك يبدأ هنا');
  await click('ابدأ رحلتي');
  await snap('03-learner-home','أكمل من حيث توقفت');
  await click('المواد');
  await snap('04-subject-library','المقررات والوحدات الدراسية');
  await click('الألعاب');
  await snap('05-learning-games','مختبر الألعاب');
  await click('حسابي');
  await snap('06-learner-profile','تعديل صفّي');
  if(errors.length)throw Error('Flutter Web errors: '+errors.join('\n'));
  await writeFile('captures/evidence.json',JSON.stringify({source:process.env.GITHUB_SHA||'local',viewport:{width:430,height:930},captures},null,2));
  console.log('Verified '+captures.length+' real Flutter screens');
}finally{await browser.close()}
