import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import * as config from 'config';
import { DbConfig } from 'config/config-types';


export const typeOrmConfig: TypeOrmModuleOptions = {
  type: "postgres",
  host: process.env.RDS_HOSTNAME,
  port: Number(process.env.PORT),
  username: process.env.RDS_USERNAME,
  password: process.env.RDS_PASSWORD,
  database: process.env.RDS_DB_NAME,
  entities: [__dirname + '/../**/*.entity{.ts,.js}'],
  synchronize: Boolean(process.env.TYPEORM_SYNC),
};
