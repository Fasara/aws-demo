import { Body, Controller, Get, Post } from '@nestjs/common';
import { TodosService } from './todos.service';

@Controller('todos')
export class TodosController {
  constructor(private readonly todosService: TodosService) {}

  @Get()
  async findAll() {
    return this.todosService.findAll();
  }

  @Post()
  async create(@Body('title') title: string) {
    return this.todosService.create(title);
  }
}
