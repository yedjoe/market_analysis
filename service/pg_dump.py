from shlex import split
from subprocess import call, PIPE, Popen

from config import DB_HOST, DB_PORT, DB_USERNAME, DB_NAME


class PGDump:
    @staticmethod
    def execute():
        p: Popen = Popen(
            split('''
                pg_dump --host={host} --port={port} --username={username} --dbname={db_name} -w --format=p --schema=public --schema-only > "E:\source_code\marketanalysis\pg_dump\schema.sql"
            '''.format(
                host=DB_HOST,
                port=DB_PORT,
                username=DB_USERNAME,
                db_name=DB_NAME
            )),
            shell=True,
            stdin=PIPE,
            stdout=PIPE,
            stderr=PIPE,
            encoding='utf8'
        )

        return p.communicate()
