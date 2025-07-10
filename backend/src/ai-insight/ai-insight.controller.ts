import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AiInsightService } from './ai-insight.service';
import { AiInsightQueryDto, AiInsightResponseDto } from './dto/ai-insight.dto';

@Controller('ai-insight')
@UseGuards(AuthGuard('jwt'))
export class AiInsightController {
  constructor(private readonly aiInsightService: AiInsightService) {}

  @Post('query')
  async queryInsight(
    @Body() queryDto: AiInsightQueryDto,
    @Request() req: any,
  ): Promise<AiInsightResponseDto> {
    const userId = req.user.id;
    return this.aiInsightService.processQuery(queryDto, userId);
  }

  @Post('chat-history')
  async getChatHistory(@Request() req: any) {
    const userId = req.user.id;
    return this.aiInsightService.getChatHistory(userId);
  }
}
