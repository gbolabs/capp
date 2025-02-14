import { ComponentFixture, TestBed } from '@angular/core/testing';

import { OtuserComponent } from './otuser.component';

describe('OtuserComponent', () => {
  let component: OtuserComponent;
  let fixture: ComponentFixture<OtuserComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [OtuserComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(OtuserComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
