BEGIN
	    RETURN (
			SELECT CFG.config_sid
			FROM public."tb_mst_config" CFG
				LEFT OUTER JOIN public."tb_mst_config_category" CAT ON CFG.config_category_sid = CAT.config_category_sid
			WHERE CAT.config_category_id = in_config_category_id
				AND CFG.config_id = in_config_id
		);
	END;