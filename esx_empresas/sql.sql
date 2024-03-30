        CREATE TABLE IF NOT EXISTS `vrp_empresas` (
            `local` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
            `user_id` VARCHAR(50) NOT NULL,
            `produtos` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
            `pesquisa` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
            `suprimentos` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
            `funcionarios` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
            `upgrade1` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
            `upgrade2` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
            `upgrade3` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
            `ganhos` INT(10) UNSIGNED NOT NULL DEFAULT '0',
            `vendas` INT(10) UNSIGNED NOT NULL DEFAULT '0',
            PRIMARY KEY (`local`, `user_id`) USING BTREE
        )
        COLLATE='utf8mb4_general_ci'
        ENGINE=InnoDB
        ;