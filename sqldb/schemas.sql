CREATE TABLE `lead_user_responses` (
  `session_id` bigint(20) unsigned NOT NULL,
  `question_key` varchar(255) NOT NULL DEFAULT '',
  `answer_value` text,
  `answer_order` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`session_id`,`question_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `lead_user_sessions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `time_completed` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ab_version` smallint(4) DEFAULT NULL,
  `utm_campaign` varchar(255) DEFAULT NULL,
  `utm_source` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `admin_empty_search` (`time_completed`,`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1414128 DEFAULT CHARSET=utf8;

CREATE TABLE `lead_users` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `phone` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`,`first_name`,`last_name`,`phone`)
) ENGINE=InnoDB AUTO_INCREMENT=342221 DEFAULT CHARSET=utf8;
