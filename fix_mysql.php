<?php

// Fix MySQL dump converted from PostgreSQL

function fix_mysql_dump($input_file, $output_file) {
    $content = file_get_contents($input_file);

    // Remove public. schema prefix
    $content = str_replace('public.', '', $content);

    // Convert timestamp(0) without time zone to DATETIME
    $content = preg_replace('/timestamp\(0\) without time zone/', 'DATETIME', $content);

    // Convert time(0) without time zone to TIME
    $content = preg_replace('/time\(0\) without time zone/', 'TIME', $content);

    // Convert bool to TINYINT(1)
    $content = str_replace('bool', 'TINYINT(1)', $content);

    // Convert numeric to DECIMAL
    $content = preg_replace('/numeric\((\d+),(\d+)\)/', 'DECIMAL($1,$2)', $content);

    // Add AUTO_INCREMENT PRIMARY KEY to id columns
    $content = preg_replace('/(    id bigint NOT NULL),/', '    id bigint NOT NULL AUTO_INCREMENT PRIMARY KEY,', $content);

    // Add AUTO_INCREMENT to other id_ columns
    $content = preg_replace('/(    id_\w+ bigint NOT NULL),/', '$1 AUTO_INCREMENT,', $content);

    // Remove AUTO_INCREMENT from other columns that got it by mistake
    $content = preg_replace('/(user_id bigint NOT NULL,) AUTO_INCREMENT,/', '$1,', $content);
    $content = preg_replace('/(id_\w+ bigint NOT NULL,) AUTO_INCREMENT,/', '$1,', $content);

    // Remove the ALTER TABLE ADD CONSTRAINT for primary keys on id
    $content = preg_replace('/ALTER TABLE \w+\s+ADD CONSTRAINT \w+_pkey PRIMARY KEY \(id\);/m', '', $content);

    // For other primary keys, keep the ALTER but remove public.
    $content = preg_replace('/ALTER TABLE (\w+)\s+ADD CONSTRAINT \w+_pkey PRIMARY KEY \((\w+)\);/m', 'ALTER TABLE $1 ADD PRIMARY KEY ($2);', $content);

    file_put_contents($output_file, $content);
    echo "Fixed file saved to $output_file\n";
}

fix_mysql_dump('avenor_schema_mysql.sql', 'avenor_schema_fixed.sql');
fix_mysql_dump('avenor_full_mysql.sql', 'avenor_full_fixed.sql');

?>

    // For other primary keys that are not id
    // This might need manual adjustment, but for now assume id columns

    file_put_contents($output_file, $content);
    echo "Fixed file saved to $output_file\n";
}

fix_mysql_dump('avenor_schema_mysql.sql', 'avenor_schema_fixed.sql');
fix_mysql_dump('avenor_full_mysql.sql', 'avenor_full_fixed.sql');

?>