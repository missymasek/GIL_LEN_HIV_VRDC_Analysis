
/*****************************
Client :  0091GIL55-34
Purpose: VRDC code to pull claims
Preparer:
Checker:
******************************/


/*****************************
 1. Define File Directories 
******************************/
* Clears the SAS log;
*Define local input, output, and temp directories;
/*libname input "V:\091GIL\34 - LEN Landscape and Planning\Work Files\Data_Summaries\VRDC\Inputs";
libname out "V:\091GIL\34 - LEN Landscape and Planning\Work Files\Data_Summaries\VRDC\Test";*/

%let StartingEnrollment = MBSF.MBSF_ABCD_2020;
%let FFS = ; /*HRT processed FFS lib*/
%let out = SH054820;
%let pfx = GIL_BW;
%let pdeyr = 2020;

	
*Options and Libraries;
OPTIONS 
	spool
	obs=max		/* Specifies number of last observation to process */
	mprint 			/* Displays the SAS statements that are generated by macro execution. */
	mlogic 			/* Causes the macro processor to trace its execution and to write the trace information to the SAS log. */
	symbolgen; 		/* Displays the results of resolving macro variable references. */

*Define macro variable for HIV;
%let HCPCS_trogarzo = ('11721'); 
%let NDC_TROGARZO = ('62064012201','62064012202');
%let NDC_RUKOBIA =  ('49702025018');

/**************************************************************************************************************8******
Identify member
Need to PULL targeted member from both Medical and Pharmacy Side
**********************************************************************************************************************/
/*Here's the difference between CLM_ID and ClaimID: ClaimID = cats("&filetype_prefix.",put(CLM_ID,z12.)); The filetype_prefix is IP, SNF, OP, PB, HSP, HHA or DME*/
/**********************************************
FFS Processing
************************************************/

/*IMPORT AND STACK REVENUE FILES and identify target patients*/

%macro inst_pull_monthly(yr,yr2,mo);

data MSSP_Revenue_IP_20&yr2.&mo.;
	set  RIFQ20&yr..inpatient_revenue_&mo. (keep = bene_id clm_id  ClaimID CLM_LINE_NUM  HCPCS_CD File REV_CNTR_UNIT_CNT REV_CNTR_TOT_CHRG_AMT)
	if hcpcs_cd IN  &HCPCS_trogarzo.; /*MNM - Changed HCPCS_hiv to HCPCS_trogarzo*/
	ClaimID = cats("IP",put(CLM_ID,z12.)); /*HRT says z12. but i think it is z15.?*/

	Length File $3.;
	File = "IP";
run;

data MSSP_Revenue_SNF_20&yr2.&mo.;
	set  RIFQ20&yr..SNF_revenue_&mo. (keep = bene_id clm_id  ClaimID CLM_LINE_NUM  HCPCS_CD  File REV_CNTR_UNIT_CNT REV_CNTR_TOT_CHRG_AMT)
	if hcpcs_cd IN  &HCPCS_trogarzo.; /*MNM - Changed HCPCS_hiv to HCPCS_trogarzo*/
	ClaimID = cats("SNF",put(CLM_ID,z12.)); 

	Length File $3.;
	File = "SNF";
run;

data MSSP_Revenue_OP_20&yr2.&mo.;
	set  RIFQ20&yr..outpatient_revenue_&mo. (keep = bene_id clm_id  ClaimID CLM_LINE_NUM  HCPCS_CD File REV_CNTR_UNIT_CNT REV_CNTR_TOT_CHRG_AMT)
	if hcpcs_cd IN  &HCPCS_trogarzo.; /*MNM - Changed HCPCS_hiv to HCPCS_trogarzo*/
	ClaimID = cats("OP",put(CLM_ID,z12.)); 

	Length File $3.;
	File = "OP";
run;

data MSSP_Revenue_PB_20&yr2.&mo.;
	set  RIFQ20&yr..bcarrier_line_&mo. (keep = bene_id clm_id  ClaimID CLM_LINE_NUM  HCPCS_CD File REV_CNTR_UNIT_CNT REV_CNTR_TOT_CHRG_AMT)
	if hcpcs_cd IN  &HCPCS_trogarzo.; /*MNM - Changed HCPCS_hiv to HCPCS_trogarzo*/
	REV_CNTR_UNIT_CNT = CARR_LINE_MTUS_CNT; /*MNM - Why are these being redefined?*/
	REV_CNTR_TOT_CHRG_AMT = LINE_ALOWD_CHRG_AMT;
	ClaimID = cats("PB",put(CLM_ID,z12.)); 

	Length File $3.;
	File = "PB";
run;

data MSSP_Revenue_HSP_20&yr2.&mo.;
	set  RRIFQ20&yr..hospice_revenue_&mo.  (keep = bene_id clm_id  ClaimID CLM_LINE_NUM  HCPCS_CD File REV_CNTR_UNIT_CNT REV_CNTR_TOT_CHRG_AMT)
	if hcpcs_cd IN  &HCPCS_trogarzo.; /*MNM - Changed HCPCS_hiv to HCPCS_trogarzo*/
	ClaimID = cats("HSP",put(CLM_ID,z12.)); 

	Length File $3.;
	File = "HSP";
run;

data MSSP_Revenue_HHA_20&yr2.&mo.;
	set  RIFQ20&yr..hha_revenue_&mo. (keep = bene_id clm_id  ClaimID CLM_LINE_NUM  HCPCS_CD File REV_CNTR_UNIT_CNT REV_CNTR_TOT_CHRG_AMT)
	if hcpcs_cd IN  &HCPCS_trogarzo.; /*MNM - Changed HCPCS_hiv to HCPCS_trogarzo*/
	ClaimID = cats("HHA",put(CLM_ID,z12.)); 

	Length File $3.;
	File = "HHA";
run;

data MSSP_Revenue_DME_20&yr2.&mo.;
	set  RIFQ20&yr..dme_line_&mo. (keep = bene_id clm_id  ClaimID CLM_LINE_NUM  HCPCS_CD File REV_CNTR_UNIT_CNT REV_CNTR_TOT_CHRG_AMT)
	if hcpcs_cd IN  &HCPCS_trogarzo.; /*MNM - Changed HCPCS_hiv to HCPCS_trogarzo*/
	REV_CNTR_UNIT_CNT = DMERC_LINE_MTUS_CNT; /*MNM - Why are these being redefined?*/
	REV_CNTR_TOT_CHRG_AMT = LINE_ALOWD_CHRG_AMT;
	ClaimID = cats("DME",put(CLM_ID,z12.));

	Length File $3.;
	File = "DME"; 
run;

data Revenue_HIV_20&yr2.&mo.;
set MSSP_Revenue_IP_20&yr2.&mo. 
	MSSP_Revenue_SNF_20&yr2.&mo.
	MSSP_Revenue_OP_20&yr2.&mo.
	MSSP_Revenue_PB_20&yr2.&mo.
	MSSP_Revenue_HSP_20&yr2.&mo.
	MSSP_Revenue_HHA_20&yr2.&mo.
	MSSP_Revenue_DME_20&yr2.&mo.;
run;

%mend inst_pull_monthly;

%macro inst_pull(yr,yr2);

%inst_pull_monthly(&yr.,&yr2.,01);
%inst_pull_monthly(&yr.,&yr2.,02);
%inst_pull_monthly(&yr.,&yr2.,03);
%inst_pull_monthly(&yr.,&yr2.,04);
%inst_pull_monthly(&yr.,&yr2.,05);
%inst_pull_monthly(&yr.,&yr2.,06);
%inst_pull_monthly(&yr.,&yr2.,07);
%inst_pull_monthly(&yr.,&yr2.,08);
%inst_pull_monthly(&yr.,&yr2.,09);
%inst_pull_monthly(&yr.,&yr2.,10);
%inst_pull_monthly(&yr.,&yr2.,11);
%inst_pull_monthly(&yr.,&yr2.,12);
%end;

%mend inst_pull;

%inst_pull(20,20);


/*STACK Monthly REVENUE*/
data &out..&pfx._ALL_Revenue_HIV;	/*BW reminder to make sure PFX is used on tables saved to permament libraries*/
	set Revenue_HIV_:;
run;

/*Save memberlist*/
proc sql;
	create table &out..&pfx._memberlist_FFS as 
	select distinct 
		bene_id, 1 as TROGARZO_FFS
	from &out..&pfx._ALL_Revenue_HIV;
quit;




/******************
PDE Processing
********************/
%macro PULL_Member_PDE(mm,year);

proc sql;
	create table demo_&mm._trogarzo as select 
		distinct 
    	BENE_ID,
		1 as TROGARZO_PDE
	from pde&year..PDE_DEMO_&year._&mm. 
	where substr(PROD_SRVC_ID,1,11) in &NDC_TROGARZO.;
quit;

proc sql;
	create table demo_&mm._RUKOBIA as select 
		distinct 
    	BENE_ID,
		1 as RUKOBIA_PDE
	from pde&year..PDE_DEMO_&year._&mm. 
	where substr(PROD_SRVC_ID,1,11) in &NDC_RUKOBIA.;
quit;


data demo_&mm.;
	merge demo_&mm._trogarzo demo_&mm._RUKOBIA;
	by bene_id;
run;

%mend PULL_Member_PDE;


%PULL_Member_PDE(01,2020);
%PULL_Member_PDE(02,2020);
%PULL_Member_PDE(03,2020);
%PULL_Member_PDE(04,2020);
%PULL_Member_PDE(05,2020);
%PULL_Member_PDE(06,2020);
%PULL_Member_PDE(07,2020);
%PULL_Member_PDE(08,2020);
%PULL_Member_PDE(09,2020);
%PULL_Member_PDE(10,2020);
%PULL_Member_PDE(11,2020);
%PULL_Member_PDE(12,2020);

/*STACK DEMO*/
data PDE_demo_stacked;
	set demo_:;
run;
/*Save memberlist*/
proc sql;
	create table &out..&pfx._memberlist_PDE as 
	select distinct bene_id, TROGARZO_PDE,RUKOBIA_PDE
	from PDE_demo_stacked;
quit;


/*FULL MEMBER LIST*/
DATA &out..&pfx._memberlist_2020;
	merge &out..&pfx._memberlist_PDE  &out..&pfx._memberlist_FFS;
	by bene_id;
run;



/************************
*Enrollment processing*
************************/
/***************************************************************
Enrollment Files  
**************************************************************/

/** Summarize MM's Across all Fields*/


data &out..&pfx._StartEnrollTemp;
	set &StartingEnrollment.;

	array MDCR_Status_CODE_ (12) MDCR_Status_CODE_01-MDCR_Status_CODE_12 ;
	array CST_SHR_GRP_CD_ (12) CST_SHR_GRP_CD_01-CST_SHR_GRP_CD_12;
	array PTC_CNTRCT_ID_ (12) PTC_CNTRCT_ID_01-PTC_CNTRCT_ID_12;
	array PTD_CNTRCT_ID_ (12) PTD_CNTRCT_ID_01-PTD_CNTRCT_ID_12;
	array LI (12) LI1-LI12;

	/*Get total LI and Dual Month for each member, note that we have total enroll in prior step*/
	/*Arrays were giving warning 'invalid numeric data' for N and Y values, swapping to 1/0*/
	do i = 1 to 12;
		if CST_SHR_GRP_CD_[i] in  ('09','10','13') then LI[i] = 0;
			else LI[i] =1;
	end;
run;


/*Reformat enrollment*/
%macro MonthlyEnroll(Month, MonthNum);
proc sql;
create table Member_Enroll_&month. as 
	select 
	a.BENE_ID,
	"&month." as Month format $2.,
	COALESCE(a.PTC_CNTRCT_ID_&month.,a.PTD_CNTRCT_ID_&month.) as Contract,
	COALESCE(a.PTC_PBP_ID_&month.,a.PTD_PBP_ID_&month.) as PBP,
	a.LI&MonthNum. as LI,
	1 as Enroll,
	b.C_D_Coverage,
	b.SNP_Type
from &out..&pfx._StartEnrollTemp where a.PTC_CNTRCT_ID_&month. not in ('') or a.PTD_PBP_ID_&month. not in ('') as a
left join &input..GIL34_plan_type as b
on COALESCE(a.PTC_CNTRCT_ID_&month.,a.PTD_CNTRCT_ID_&month.) = b.contract and COALESCE(a.PTC_PBP_ID_&month.,a.PTD_PBP_ID_&month.)  = b.PBP;
quit;
%mend;

%MonthlyEnroll(01,1);
%MonthlyEnroll(02,2);
%MonthlyEnroll(03,3);
%MonthlyEnroll(04,4);
%MonthlyEnroll(05,5);
%MonthlyEnroll(06,6);
%MonthlyEnroll(07,7);
%MonthlyEnroll(08,8);
%MonthlyEnroll(09,9);
%MonthlyEnroll(10,10);
%MonthlyEnroll(11,11);
%MonthlyEnroll(12,12);

/*Stack all tables*/
data &out..&pfx._Member_Enroll_Full;	
set Member_Enroll_01 - Member_Enroll_12;

if C_D_Coverage in ('','.') and substr(contract,1,1)in ('S') then Plan_Type = 'PDP'; 
else if C_D_Coverage in ('MA-PD','MA Only') or substr(contract,1,1) in('H') then Plan_Type = 'MAPD' ;
else Plan_Type = 'OTH';

run;

/*BW Dropping monthly tables to save space*/
proc sql;
	drop table Member_Enroll_01;	drop table Member_Enroll_02;	drop table Member_Enroll_03;
	drop table Member_Enroll_04;	drop table Member_Enroll_05;	drop table Member_Enroll_06;
	drop table Member_Enroll_07;	drop table Member_Enroll_08;	drop table Member_Enroll_09;
	drop table Member_Enroll_10;	drop table Member_Enroll_11;	drop table Member_Enroll_12;
quit;

* Limit to HIV members only to shrink data size;
data &out..&pfx._Member_Enroll_HIV;
set &out..&pfx._Member_Enroll_Full;
	if _n_ eq 1 then do;
			declare hash HIV_m(dataset:"&out..&pfx._memberlist_2020");
			rc =  HIV_m.definekey ("BENE_ID");
			rc =  HIV_m.definedata (); 
			rc =  HIV_m.definedone ();
	end;
		rc= HIV_m.find();
		If rc=0 then HIV_Member = 1; else HIV_Member = 0;
	Drop rc;
if HIV_Member = 1;
run;


proc sql;
	drop table &out..&pfx._StartEnrollTemp;
quit;


		
/**************************************************************************************************************8******
Get Claims for targeted members
Need to PULL targeted member from both Medical and Pharmacy Side
**********************************************************************************************************************/

/***************************************************************
PDE Files  
**************************************************************/

/*Pulls PDE Pre-Extracted by Month*/
%macro Monthlydata_pde(mm,quar,year);	
proc sql;
	create table demo as select 
		&mm. as PDE_month,
    	a.BENE_ID,
		a.PDE_ID, /*PDE LINK*/
		a.BRND_GNRC_CD,
		substr(a.PROD_SRVC_ID,1,11) as NDC,
		a.DAYS_SUPLY_NUM,
        case when abs(a.DAYS_SUPLY_NUM) le 31 then '30'
            when abs(a.DAYS_SUPLY_NUM) gt 84 then '90' else '60' end as Day30_90,
    	a.PTNT_PAY_AMT,
    	a.QTY_DSPNSD_NUM,
    	a.TOT_RX_CST_AMT as Total_Drug_Cost_amt,
		a.SRVC_DT as SRVC_DT format mmddyy10.,
		case when a.SRVC_DT is not null then put(month(a.SRVC_DT),z2.) else '00' end as month format $2.,	
        case when a.DAYS_SUPLY_NUM < 0 then -1 else 1 end as scripts
	from pde&year..PDE_DEMO_&year._&mm. a /*where a.year = &year.*/
	order by a.bene_id, a.pde_id,a.SRVC_DT;


	create table encrypt_link as select 
    	a.BENE_ID,
		a.PDE_ID,
		a.SRVC_DT as SRVC_DT format mmddyy10. ,
		a.PLAN_CNTRCT_REC_ID as Contract,
    	a.PLAN_PBP_REC_NUM as PBP
    from pde&year..PDE_ENCRYPT_LINK_&year._&mm. a
	order by a.bene_id, a.pde_id,a.SRVC_DT;

	create table dispensing as select 
		a.BENE_ID,
		a.PDE_ID,
		a.DSPNSNG_STUS_CD, /*Partial/full fill*/
		case when a.PHRMCY_SRVC_TYPE_CD = '01' then 'Retail'
			 when a.PHRMCY_SRVC_TYPE_CD = '06' then 'Mail' 
			 /*when  a.PHRMCY_SRVC_TYPE_CD = '04' then 'INST' Institutional claims*/
			 else 'Other' end as PHRMCY_SRVC_TYPE,
		a.SRVC_DT as SRVC_DT format mmddyy10.
		from pde&year..PDE_DISPENSING_&year._&mm. a
	order by a.bene_id, a.pde_id,a.SRVC_DT;


	create table pmt_dtls as select 
		a.BENE_ID,
		a.PDE_ID,
		a.SRVC_DT,
		/*a.BENEFIT_PHASE, really detailed*/
		/*a.CTSTRPHC_CVRG_CD,Catastrophic Coverage Code*/
		a.CVRD_D_PLAN_PD_AMT as CPP_amt,
		a.NCVRD_PLAN_PD_AMT as NPP_amt,
		a.GDC_ABV_OOPT_AMT as GDCA_amt,
		a.GDC_BLW_OOPT_AMT as GDCB_amt,
		a.LICS_AMT,
		a.OTHR_TROOP_AMT,
		a.PLRO_AMT,
		a.RPTD_GAP_DSCNT_NUM as CGDP_amt 
		from pde&year..PDE_PMT_DTLS_&year._&mm. a
	order by a.bene_id, a.pde_id,a.SRVC_DT;
quit;


data pde_stacked_&year._&mm.;
	merge demo encrypt_link pmt_dtls dispensing;
	by bene_id pde_id SRVC_DT;
run;

proc sql;
	drop table demo;
	drop table encrypt_link;
	drop table pmt_dtls;
	drop table dispensing;
quit;


data pde_stacked_&year._HIV_&mm.;	
set pde_stacked_&year._&mm.;

	length drug_type $3.;
	if _n_ eq 1 then do;
			declare hash FAT(dataset:"_uplds.ndc_map");	
			rc =  FAT.definekey ("NDC");
			rc =  FAT.definedata ("drug_type"); 
			rc =  FAT.definedone ();
	end;
		rc= FAT.find();
		If rc=0 then In_FAT = 1; else In_FAT = 0;
	Drop rc;

	length TROGARZO_PDE 8.  RUKOBIA_PDE 8. TROGARZO_FFS 8.;
	if _n_ eq 1 then do;
			declare hash HIV_m(dataset:"&out..&pfx._memberlist_2020");
			rc =  HIV_m.definekey ("BENE_ID");
			rc =  HIV_m.definedata ("TROGARZO_PDE","RUKOBIA_PDE","TROGARZO_FFS"); 
			rc =  HIV_m.definedone ();
	end;
		rc= HIV_m.find();
		If rc=0 then HIV_Member = 1; else HIV_Member = 0;
	Drop rc;

*LImit to HIV member;
	if HIV_Member = 1;
run;


proc sql; drop table  pde_stacked_&year._&mm.; quit;

%mend Monthlydata_pde;


%Monthlydata_pde(01,Q1,2020);
%Monthlydata_pde(02,Q1,2020);
%Monthlydata_pde(03,Q1,2020);
%Monthlydata_pde(04,Q2,2020);
%Monthlydata_pde(05,Q2,2020);
%Monthlydata_pde(06,Q2,2020);
%Monthlydata_pde(07,Q3,2020);
%Monthlydata_pde(08,Q3,2020);
%Monthlydata_pde(09,Q3,2020);
%Monthlydata_pde(10,Q4,2020);
%Monthlydata_pde(11,Q4,2020);
%Monthlydata_pde(12,Q4,2020);


/*Stack all tables*/
data &out..&pfx._pde_&pdeyr.;	
set pde_stacked_&pdeyr._HIV_01 - pde_stacked_&pdeyr._HIV_12;

	* Develop B_G flag;
	length B_G $3.;
	if Drug_Type in ("GEN") then B_G = "G";
	else if Drug_Type in ("SSB","MSB") then B_G="B";
	else B_G = "UNK";

	
	if NDC in &NDC_RUKOBIA. then Drug = 'RUKOBIA';
	else if NDC in &NDC_TROGARZO. then Drug ='TROGARZO';
	else Drug = 'Other';
	
run;


/*********************************************************
FFS Processing
**************************************************************/

*Pull claims;
/***********************************************/
%macro Pull_FFS(type,yearmo);

data FFS_Claims_&type._&yearmo. (Keep = 
	Bene_ID YearMO MR_Line_Case MR_Cases_Admits MR_Units_Days MR_Procs Clm_ID Clm_Line_Num MR_Billed MR_Allowed MR_Paid MR_Coinsurance MR_Deductible MR_PatientPay
	REV_CNTR_TOT_CHRG_AMT TROGARZO_PDE RUKOBIA_PDE TROGARZO_FFS);	
set &HRT..HRT_HCG_&type._&Yearmo.;

*Trogarzo claims from revenue;
length REV_CNTR_TOT_CHRG_AMT 8.; /*tag charged amount to double check the hash works*/
	if _n_ eq 1 then do;
			declare hash HIV_clm(dataset:"&out..&pfx._ALL_Revenue_HIV (rename =(ClaimID = Clm_ID))");
			rc =  HIV_clm.definekey ("BENE_ID","Clm_ID","Clm_Line_Num");
			rc =  HIV_clm.definedata ("REV_CNTR_TOT_CHRG_AMT"); 
			rc =  HIV_clm.definedone ();
	end;
		rc= HIV_clm.find();
		If rc=0 then HIV_clm = 1; else HIV_clm = 0;
	Drop rc;

*Limit to HIV patients;
	length TROGARZO_PDE 8.  RUKOBIA_PDE 8. TROGARZO_FFS 8.;
	if _n_ eq 1 then do;
			declare hash HIV_m(dataset:"&out..&pfx._memberlist_2020");
			rc =  HIV_m.definekey ("BENE_ID");
			rc =  HIV_m.definedata ("TROGARZO_PDE","RUKOBIA_PDE","TROGARZO_FFS"); 
			rc =  HIV_m.definedone ();
	end;
		rc= HIV_m.find();
		If rc=0 then HIV_Member = 1; else HIV_Member = 0;
	Drop rc;

if HIV_Member = 1;
quit;
%mend Pull_FFS;

%Pull_FFS(DME,2020_ALL);
%Pull_FFS(HHA,2020_ALL);
%Pull_FFS(HSP,2020_ALL);
%Pull_FFS(IP,2020_ALL);
%Pull_FFS(SNF,2020_ALL);

%Pull_FFS(OP,2020_01);
%Pull_FFS(OP,2020_02);
%Pull_FFS(OP,2020_03);
%Pull_FFS(OP,2020_04);
%Pull_FFS(OP,2020_05);
%Pull_FFS(OP,2020_06);
%Pull_FFS(OP,2020_07);
%Pull_FFS(OP,2020_08);
%Pull_FFS(OP,2020_09);
%Pull_FFS(OP,2020_10);
%Pull_FFS(OP,2020_11);
%Pull_FFS(OP,2020_12);

%Pull_FFS(PB,2020_01);
%Pull_FFS(PB,2020_02);
%Pull_FFS(PB,2020_03);
%Pull_FFS(PB,2020_04);
%Pull_FFS(PB,2020_05);
%Pull_FFS(PB,2020_06);
%Pull_FFS(PB,2020_07);
%Pull_FFS(PB,2020_08);
%Pull_FFS(PB,2020_09);
%Pull_FFS(PB,2020_10);
%Pull_FFS(PB,2020_11);
%Pull_FFS(PB,2020_12);

*STACK CLAIMS;

data &out..&pfx._FFS_All_Claims ;
	set FFS_Claims_: ;

	month = substr(put(yearmo,6.),5,6);

*Flagging by claim_type;
	length claim_type $3.;
	if substr(mr_line_Case,1,1) = "I" then claim_type = "IP" ;
	else if substr(mr_line_Case,1,1) = "O" then claim_type = "OP";
	else if substr(mr_line_Case,1,2) in("P1","P2","P3","P4","P5","P6","P7") then claim_type = "PS";
	else if substr(mr_line_Case,1,2) in("P8","P9") then claim_type = "OS";
	end;

run;


/***************************************************************
Merger on Enrollment
**************************************************************/
*Merge Enrollment onto Claims;

proc sql;
	create table &out..&pfx._pde_&pdeyr._2 as
	select 
		a.*
		,b.contract
		,b.plan_type
		,b.PBP
		,b.LI
		,b.SNP_Type
		,b.C_D_Coverage
		,case when b.month is missing then 0 else 1 end as enroll_find
	from &out..&pfx._pde_&pdeyr. as a
	left join &out..&pfx._Member_Enroll_HIV as b
	on a.BENE_ID = b.BENE_ID and a.Month = b.Month
	;
quit;
/*BW Dropping table*/
proc sql; drop table &out..&pfx._pde_&pdeyr.; quit;

*Merge Enrollment onto Claims;

proc sql;
	create table &out..&pfx._FFS_All_Claims_2 as
	select 
		a.*
		,b.contract
		,b.plan_type
		,b.PBP
		,b.LI
		,b.SNP_Type
		,b.C_D_Coverage
		,case when b.month is missing then 0 else 1 end as enroll_find
	from &out..&pfx._FFS_All_Claims as a
	left join &out..&pfx._Member_Enroll_HIV as b
	on a.BENE_ID = b.BENE_ID and a.Month = b.Month
	;
quit;
/*Don't drop the claim table yet*/


/***************************************************************
summary
**************************************************************/
/*Summarize Rev Tables/HIV Claims for checking purpose*/
proc summary nway missing data= &out..&pfx._ALL_Revenue_HIV ;
	class File;
	var REV_CNTR_UNIT_CNT REV_CNTR_TOT_CHRG_AMT;
	output out= &out..&pfx._HIV_Revenue_Summary (drop=_type_ rename=(_freq_=Row_Ct))
	sum=;
run;


*Define macro Variables for Claims Fields;
%LET CatVarsCl =  Plan_Type SNP_Type LI B_G Drug TROGARZO_PDE RUKOBIA_PDE TROGARZO_FFS;
%LET NumVarsCl = scripts QTY_DSPNSD_NUM DAYS_SUPLY_NUM GDCB_amt GDCA_amt PTNT_PAY_AMT OTHR_TROOP_AMT LICS_AMT PLRO_AMT CPP_AMT NPP_AMT TOTAL_DRUG_COST_AMT;
		
proc summary nway missing data= &out..&pfx._pde_&pdeyr._2  ;
	class &CatVarsCl.;
	var &NumVarsCl.;
	output out= &out..&pfx._Pharm_Claim_Summary (drop=_type_ rename=(_freq_=Row_Ct))
	sum=;
run;

*Define macro Variables for Claims Fields;
%LET CatVarsC2 =  Plan_Type SNP_Type LI claim_type HIV_clm TROGARZO_PDE RUKOBIA_PDE TROGARZO_FFS;
%LET NumVarsC2 = MR_Cases_Admits MR_Units_Days MR_Procs Clm_ID Clm_Line_Num MR_Billed MR_Allowed MR_Paid MR_Coinsurance MR_Deductible MR_PatientPay REV_CNTR_TOT_CHRG_AMT;
proc summary nway missing data= &out..&pfx._MSSP_&pdeyr._2  ;
	class &CatVarsC2.;
	var &NumVarsC2.;
	output out= &out..&pfx._Medical_Claim_Summary (drop=_type_ rename=(_freq_=Row_Ct))
	sum=;
run;


/*summarize final fields for Enrollment*/
proc summary data= &out..&pfx._Member_Enroll_Full nway missing;
  	class Plan_Type SNP_Type C_D_Coverage ;
	var LI Enroll;
  	output out= &out..&pfx._Enrollment_ALL (drop=_type_ _freq_) sum =;
run;

/*summarize final fields for HIV Enrollment*/
proc summary data= &out..&pfx._Member_Enroll_HIV nway missing;
  	class Plan_Type SNP_Type C_D_Coverage ;
	var LI Enroll;
  	output out= &out..&pfx._Enrollment_HIV (drop=_type_ _freq_) sum =;
run;

Proc sql;
create table &out..&pfx._Member_count as 
select 
	TROGARZO_PDE, RUKOBIA_PDE, TROGARZO_FFS, count(distinct bene_id) as member_count
	from &out..&pfx._memberlist_2020
	group by TROGARZO_PDE, RUKOBIA_PDE, TROGARZO_FFS;
quit;
