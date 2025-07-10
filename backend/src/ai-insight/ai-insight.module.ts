import { Module } from '@nestjs/common';
import { AiInsightController } from './ai-insight.controller';
import { AiInsightService } from './ai-insight.service';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [AiInsightController],
  providers: [AiInsightService, PrismaService],
  exports: [AiInsightService],
})
export class AiInsightModule {}
