import { Test, TestingModule } from '@nestjs/testing';
import { TimService } from './tim.service';

describe('TimService', () => {
  let service: TimService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [TimService],
    }).compile();

    service = module.get<TimService>(TimService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
