# ====================	
# expl_analysis_smooth_and_modes
# ====================	
	
	# Nuno Prista, 2017-2018
	
	
	# 2018-09-10: "extracted from sample_level_funs1.r"
	# 2018-05-28: streamlined some arguments (added sampDesign, var_table; changed names) 


func_detect_modes_in_samples<-function(x, variable = "lenCls", original_class_span , smooth_class_span, min_proportion_to_accept_mode, sampDesign, var_table)
{
	# identifies modes and stores results of modal analyses
		# note: numerical and categorical variables are processed differently
	
	# x (data.frame) is an RDB CA
	# variable (string) is the variable to analyze [one of the columns of x] 
	# original_class_span (integer) is the size of original class span in samples
	# smooth_class_span (integer) is the size of desired smooth class span
	# min_proportion_to_accept_mode (decimal) is the minimum proportion of the LF that a mode must have to be accepted (e.g., 0.05)
	# sampDesign is a list of sampling design details, including "strata_var"
	# var_table is a data.frame with variable and variable tupe (e.g., support variable_table)

	# x <- df1[,c(sampDesign$strata_var, var1)]
				# t1<-table(df1[sampling_options$strata_var])
				# colnames(x)<-c("strata_id", variable)
					# t2<-table(x$strata_id)
					# x$total_strata <- t1[match(x$strata_id, names(t1))]
				# x$samp_weight <- x$total_strata/(t2[match(x$strata_id, names(t2))])					
				# freq_dist_pop_estimate_no_NAs<-tapply(x$samp_weight, x[,variable], sum)

	a <- tapply(x[[variable]], x$sampId, function(x) sum(!is.na(x)))
	if(sum(a[a<10])>0){stop("Some samples have less than 10 non-NA values for target_variable - you need to exclude them from dataset")}
	
	if (is.character(x[[variable]])) {x[[variable]]<-factor(is.character(x[[variable]]))}
	
	out<-sapply(unique(x$sampId), function(x) NULL)
	
	ls1<-split(x, x$sampId)
		
	ls2<-lapply(ls1, function(x){ 
	#print(paste("processing sample", as.character(x$sampId[1]))) 
	#print(variable)
		# if stratified and variable is not the stratification variable, then performs the raising 
			if(sampDesign$stratified==TRUE & variable!=sampDesign$strata_var)
				{
					
				# computes totals for strata_var
					if(sampDesign$strata_var %in% var_table$variable[var_table$variable=="numerical"])
						{
						t1<-table(factor(x[[sampDesign$strata_var]], levels=seq(min(x[[sampDesign$strata_var]], na.rm=T), max(x[[sampling_design$strata_var]], na.rm=T), by=variable_table[variable_table$variable == sampling_design$strata_var, "original_class_span"])))
						} else
							{
							t1<-table(x[[sampDesign$strata_var]], useNA="al")
							}
				# extracts strata_var and target_var
					#browser()
					x <- x[,c(sampDesign$strata_var, variable)]
				colnames(x)<-c("strata_id", variable)
				# computes raised freq dist [NAs are considered]
					t2<-table(x$strata_id, useNA="al")
					x$total_strata <- t1[match(x$strata_id, names(t1))]
					x$samp_weight <- x$total_strata/(t2[match(x$strata_id, names(t2))])
					print(sum(x$samp_weight)==nrow(x))
					freq_dist_pop_estimate<-tapply(x$samp_weight, factor(x[,variable], exclude=NULL), sum)
					freq_dist_pop_estimate_no_NAs<-freq_dist_pop_estimate[!is.na(names(freq_dist_pop_estimate))]
				# creates dummy dataset to enter analysis
				x<-data.frame(1,rep(names(freq_dist_pop_estimate),freq_dist_pop_estimate))	
				names(x)<-c("dummy",variable)
				if(var_table[var_table$variable==variable,"type"]=="numerical"){x[[variable]]<-as.numeric(x[[variable]])}
				}
	
		if(!is.factor(x[[variable]]))
			{
		# frequency tables (original and smooth) [NAs are not considered]
			
			original_freq<-table(factor(x[[variable]], levels=seq(min(x[[variable]], na.rm=T), max(x[[variable]], na.rm=T), by=original_class_span)), useNA="al")
			tmp.lt<-x[[variable]]-x[[variable]]%%smooth_class_span
			smoothed_freq<-table(factor(tmp.lt, levels=seq(min(tmp.lt, na.rm=T), max(tmp.lt, na.rm=T), by=smooth_class_span))); smoothed_freq
			} else {
					original_class_span<-NA
					smooth_class_span<-NA
					original_freq<-table(x[[variable]], useNA="al")
					smoothed_freq<-NA
					}
			
			
		# modes determination
			sample_threshold_for_modes <- min_proportion_to_accept_mode * nrow(x)
			
			if(length(unique(table(x[,variable])))>1) # condition for mode existence
				{
				if(!is.factor(x[[variable]])) # different processing of numerical and categorical variable
				{
					original_modes = localMaxima2(as.numeric(table(factor(x[[variable]], levels=seq(min(x[[variable]], na.rm=T), max(x[[variable]], na.rm=T), by=original_class_span)))))
					original_modes_after_threshold<-original_modes[original_modes %in% which(original_freq[!is.na(names(original_freq))]>sample_threshold_for_modes)]			
					if (length(unique(x[[variable]]))>1){
							smoothed_modes = localMaxima2(as.numeric(table(factor(tmp.lt, levels=seq(min(tmp.lt, na.rm=T), max(tmp.lt, na.rm=T), by=smooth_class_span)))))
							smoothed_modes_after_threshold<-smoothed_modes[smoothed_modes %in% which(smoothed_freq>sample_threshold_for_modes)]
							} else { smoothed_modes = original_modes; original_modes_after_threshold = original_modes_after_threshold}
					} else {
							original_modes = localMaxima2(as.numeric(table(x[[variable]])))
							original_modes_after_threshold<-original_modes[original_modes %in% which(original_freq>sample_threshold_for_modes)]			
							smoothed_modes <- NA
							smoothed_modes_after_threshold <- NA
						}
				} else {
						original_modes <- NA
						original_modes_after_threshold <- NA		
						smoothed_modes <- NA
						smoothed_modes_after_threshold <- NA						
						}
				
			ls_auto_modes<-list()
		#browser()
			ls_auto_modes [[variable]]<- list (
												total_n=nrow(x),
												NAs=sum(is.na(x[[variable]])),
												original_class_span = original_class_span,
												original_breaks = names(original_freq),
												original_freq = original_freq, 
												original_modes = original_modes_after_threshold, #NAs are excluded
												smooth_class_span = smooth_class_span,
												smooth_breaks = names(smoothed_freq),
												smoothed_freq = smoothed_freq,
												smooth_modes = smoothed_modes_after_threshold,
												threshold_for_modes = sample_threshold_for_modes,
												min_proportion_to_accept_mode = min_proportion_to_accept_mode
											)
			ls_auto_modes								
		})									
		ls2
	}
