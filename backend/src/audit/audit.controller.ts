import { Controller, Get, Query, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuditService } from './audit.service';
import { GetAuditLogDto } from './dto/audit.dto';

@Controller('audit')
@UseGuards(AuthGuard('jwt'))
export class AuditController {
  constructor(private readonly auditService: AuditService) {}

  @Get('logs')
  async getAuditLogs(@Request() req, @Query() query: GetAuditLogDto) {
    return this.auditService.getAuditLogs(req.user, query);
  }
}
