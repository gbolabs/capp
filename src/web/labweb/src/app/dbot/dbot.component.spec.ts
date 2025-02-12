import { ComponentFixture, TestBed } from '@angular/core/testing';
import { DbotComponent } from './dbot.component';

describe('DbotComponent', () => {
  let component: DbotComponent;
  let fixture: ComponentFixture<DbotComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DbotComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DbotComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
