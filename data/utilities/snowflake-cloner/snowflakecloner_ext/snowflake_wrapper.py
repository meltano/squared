from snowflake.connector import connect


class SnowflakeWrapper:

    def __init__(
            self,
            user,
            password,
            account,
            warehouse,
            role
        ):
        self.user = user
        self.password = password
        self.account = account
        self.warehouse = warehouse
        self.role = role
        self._connection = self._connect()


    def _connect(self):
        print('Connecting')
        return connect(
            user=self.user,
            password=self.password,
            account=self.account,
            warehouse=self.warehouse,
            role=self.role
        )

    
    def execute(self, command, fetch=False):
        try:
            cursor = self._connection.cursor()
            query = cursor.execute(command)
            if fetch:
                return query.fetchall()
            else:
                return
        finally:
            cursor.close()
