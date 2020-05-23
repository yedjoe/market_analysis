BEGIN
	    RETURN QUERY
			SELECT CFG.config_sid,
				CAT.config_category_id,
				CFG.config_id,
				CFG.config_val,
				CFG.description
			FROM public."tb_mst_config" CFG
				LEFT OUTER JOIN public."tb_mst_config_category" CAT ON CFG.config_category_sid = CAT.config_category_sid
			WHERE CAT.config_category_id = in_config_category_id;
	END;