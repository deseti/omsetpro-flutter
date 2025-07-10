import { IsString, IsOptional, IsDateString, IsInt } from 'class-validator';
import { Transform } from 'class-transformer';

export class AiInsightQueryDto {
  @IsString()
  query: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @Transform(({ value }) => parseInt(value))
  @IsInt()
  cabangId?: number;

  @IsOptional()
  @IsString()
  context?: string; // For conversation context
}

export class AiInsightResponseDto {
  insight: string;
  data?: any;
  suggestions?: string[];
  chartData?: any;
  confidence?: number;
}
