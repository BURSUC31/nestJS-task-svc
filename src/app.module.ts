import { Module } from '@nestjs/common';
import { TasksModule } from './tasks/tasks.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { typeOrmConfig } from './config/typeorm.config';
import { Task } from './tasks/task.entity';
import { TaskRepository } from './tasks/task.repository';

@Module({
  imports: [
    TypeOrmModule.forRoot(typeOrmConfig),
    TasksModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule { }
