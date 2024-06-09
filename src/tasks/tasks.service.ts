import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { CreateTaskDto } from './dto/create-task.dto';
import { GetTasksFilterDto } from './dto/get-tasks-filter.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Task } from './task.entity';
import { TaskStatus } from './task-status.enum';
import { TaskRepository } from './task.repository';
import { DeleteResult } from 'typeorm';



@Injectable()
export class TasksService {
  constructor(
    private readonly taskRepository: TaskRepository
  ) { }

  async getTasks(filterDto: GetTasksFilterDto): Promise<Task[]> {
    const tasks = await this.taskRepository.getTasks(filterDto)
    return tasks
  }

  // getAllTasks(): Task[] {
  //     return this.tasks
  // }

  // getAllTasksWhithFilter(filterDto: GetTasksFilterDto): Task[] {
  //     const { status, search } = filterDto
  //     let tasks = this.getAllTasks()
  //     if (status) {
  //         tasks = tasks.filter((task) => task.status === status)
  //     }
  //     if (search) {
  //         tasks = tasks.filter((task) =>
  //             task.title.includes(search) ||
  //             task.description.includes(search))
  //     }
  //     return tasks
  // }


  async getTaskById(id: number): Promise<Task> {
    const found = await this.taskRepository.findOne({ where: { id } });

    if (!found) {
      throw new NotFoundException(`Task with ID ${id} not found`);
    }
    return found;
  }


  async createTask(createTaskDto: CreateTaskDto): Promise<Task> {
    return this.taskRepository.createTask(createTaskDto)
  }

  async deleteTask(id: number): Promise<DeleteResult> {
    const affectedRows = await this.taskRepository.delete(id)
    if (!affectedRows.affected) {
      throw new NotFoundException(`Task with ID ${id} not found`);
    }
    return affectedRows.raw
  }

  async updateTask(id: number, status: TaskStatus): Promise<Task> {
    const task = await this.getTaskById(id)
    task.status = status
    await task.save()

    return task
  }


}
