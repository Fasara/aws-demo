import { Injectable } from '@nestjs/common';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  ScanCommand,
} from '@aws-sdk/lib-dynamodb';
import { randomUUID } from 'crypto';

const client = new DynamoDBClient({ region: 'eu-west-2' });
const ddbDocClient = DynamoDBDocumentClient.from(client);

@Injectable()
export class TodosService {
  async findAll() {
    const result = await ddbDocClient.send(
      new ScanCommand({ TableName: 'todos' }),
    );
    return result.Items ?? [];
  }

  async create(title: string) {
    const todo = {
      id: randomUUID(),
      title,
      createdAt: new Date().toISOString(),
    };

    await ddbDocClient.send(
      new PutCommand({
        TableName: 'todos',
        Item: todo,
      }),
    );

    return todo;
  }
}
